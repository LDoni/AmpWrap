#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]
loess_model_arg <- ifelse(length(args) >= 3, args[3], "auto")
bigdata_mode <- tolower(ifelse(length(args) >= 4, args[4], "no")) == "yes"
thread_count_arg <- ifelse(length(args) >= 5, args[5], "1")

options(warn = -1)
suppressPackageStartupMessages(library(dada2))
base_loess_errfun <- get("loessErrfun", asNamespace("dada2"))

configure_parallelism <- function(value) {
    threads <- suppressWarnings(as.integer(value))
    if (is.na(threads) || threads < 1) {
        threads <- 1L
    }
    Sys.setenv(
        RCPP_PARALLEL_NUM_THREADS = threads,
        OMP_NUM_THREADS = threads,
        OPENBLAS_NUM_THREADS = threads,
        MKL_NUM_THREADS = threads,
        VECLIB_MAXIMUM_THREADS = threads,
        BLIS_NUM_THREADS = threads
    )
    if (requireNamespace("RcppParallel", quietly = TRUE)) {
        RcppParallel::setThreadOptions(numThreads = threads)
    }
    if (threads <= 1L) FALSE else TRUE
}

dada2_multithread <- configure_parallelism(thread_count_arg)

QUAL_SCAN_FILES <- 2
QUAL_SCAN_READS <- 4000
AUTO_SPLITS <- 3
AUTO_MARGIN <- 0.005
AUTO_TRAIN_NBASES <- 1500000
BIGDATA_LEARN_NBASES <- 1e8

normalize_request <- function(value) {
    if (is.null(value) || is.na(value) || value == "") {
        return("auto")
    }

    lowered <- tolower(trimws(as.character(value)))
    if (lowered %in% c("na", "none")) {
        return("vanilla")
    }
    if (!(lowered %in% c("auto", "vanilla", "1", "2", "3", "4"))) {
        stop("loess_model must be one of: auto, vanilla, 1, 2, 3, 4")
    }
    lowered
}

build_loess_errfun <- function(weight_mode = "tot", span = 0.75, pseudocount = 1) {
    function(trans) {
        qq <- as.numeric(colnames(trans))
        fallback <- tryCatch(base_loess_errfun(trans), error = function(e) NULL)
        est <- matrix(0, nrow = 0, ncol = length(qq))

        fallback_row <- function(row_name) {
            if (!is.null(fallback) && row_name %in% rownames(fallback)) {
                return(fallback[row_name, ])
            }
            rep(1e-07, length(qq))
        }

        for (nti in c("A", "C", "G", "T")) {
            for (ntj in c("A", "C", "G", "T")) {
                if (nti != ntj) {
                    row_name <- paste0(nti, "2", ntj)
                    errs <- trans[row_name, ]
                    tot <- colSums(trans[paste0(nti, "2", c("A", "C", "G", "T")), , drop = FALSE])
                    pred_prob <- fallback_row(row_name)

                    rlogp <- log10((errs + pseudocount) / tot)
                    rlogp[is.infinite(rlogp)] <- NA

                    weights <- switch(
                        weight_mode,
                        "log10_tot" = log10(pmax(tot, 10)),
                        "sqrt_tot" = sqrt(tot),
                        "none" = rep(1, length(tot)),
                        tot
                    )

                    valid <- is.finite(rlogp) & is.finite(weights) & weights > 0
                    if (sum(valid) >= 4 && length(unique(qq[valid])) >= 4) {
                        df <- data.frame(q = qq[valid], rlogp = rlogp[valid], weights = weights[valid])
                        fit <- tryCatch(
                            suppressWarnings(loess(
                                rlogp ~ q,
                                data = df,
                                weights = df$weights,
                                span = span,
                                control = loess.control(surface = "direct")
                            )),
                            error = function(e) NULL
                        )

                        if (!is.null(fit)) {
                            pred <- suppressWarnings(predict(fit, qq))
                            valid_pred <- which(is.finite(pred))
                            if (length(valid_pred) > 0) {
                                pred[seq_along(pred) > max(valid_pred)] <- pred[[max(valid_pred)]]
                                pred[seq_along(pred) < min(valid_pred)] <- pred[[min(valid_pred)]]
                                pred_prob <- 10^pred
                                pred_prob[!is.finite(pred_prob)] <- fallback_row(row_name)[!is.finite(pred_prob)]
                            }
                        }
                    }

                    pred_prob[pred_prob > 0.25] <- 0.25
                    pred_prob[pred_prob < 1e-07] <- 1e-07
                    pred_prob <- cummin(pred_prob)
                    est <- rbind(est, pred_prob)
                }
            }
        }

        err <- rbind(
            1 - colSums(est[1:3, ]),
            est[1:3, ],
            est[4, ],
            1 - colSums(est[4:6, ]),
            est[5:6, ],
            est[7:8, ],
            1 - colSums(est[7:9, ]),
            est[9, ],
            est[10:12, ],
            1 - colSums(est[10:12, ])
        )
        rownames(err) <- paste0(rep(c("A", "C", "G", "T"), each = 4), "2", c("A", "C", "G", "T"))
        colnames(err) <- colnames(trans)
        err
    }
}

MODEL_DEFS <- list(
    vanilla = list(label = "vanilla", errfun = NULL),
    `1` = list(label = "1", errfun = build_loess_errfun(weight_mode = "log10_tot", span = 2)),
    `2` = list(label = "2", errfun = build_loess_errfun(weight_mode = "sqrt_tot", span = 2)),
    `3` = list(label = "3", errfun = build_loess_errfun(weight_mode = "tot", span = 2)),
    `4` = list(label = "4", errfun = build_loess_errfun(weight_mode = "none", span = 2))
)

list_filtered_files <- function(pattern) {
    files <- list.files(input_dir, pattern = pattern, full.names = TRUE)
    files[order(basename(files))]
}

sample_quality_values <- function(files, max_files = QUAL_SCAN_FILES, max_reads = QUAL_SCAN_READS) {
    unique_q <- integer(0)

    for (file_path in head(files, max_files)) {
        con <- gzfile(file_path, open = "rt")
        block <- readLines(con, n = max_reads * 4)
        close(con)
        if (length(block) < 4) {
            next
        }

        quality_lines <- block[seq(4, length(block), by = 4)]
        if (length(quality_lines) == 0) {
            next
        }

        chars <- unique(unlist(strsplit(quality_lines, "", fixed = TRUE)))
        if (length(chars) > 0) {
            unique_q <- union(unique_q, utf8ToInt(chars) - 33L)
        }
    }

    sort(unique_q)
}

qualities_are_binned <- function(unique_q) {
    if (length(unique_q) == 0) {
        return(FALSE)
    }
    length(unique_q) <= 12
}

learn_model <- function(files, model_key, nbases = NULL, randomize = TRUE) {
    model_def <- MODEL_DEFS[[model_key]]
    learn_args <- list(
        fls = files,
        multithread = dada2_multithread,
        randomize = randomize,
        verbose = FALSE
    )

    if (!is.null(nbases)) {
        learn_args$nbases <- nbases
    }
    if (is.null(model_def$errfun)) {
        do.call(learnErrors, learn_args)
    } else {
        learn_args$errorEstimationFunction <- model_def$errfun
        do.call(learnErrors, learn_args)
    }
}

score_model <- function(trans, err_out) {
    if (is.null(trans) || sum(trans) == 0) {
        return(Inf)
    }

    probs <- err_out[rownames(trans), colnames(trans), drop = FALSE]
    probs <- pmax(pmin(probs, 1 - 1e-12), 1e-12)
    -sum(trans * log(probs)) / sum(trans)
}

score_validation <- function(validation_files, err_out) {
    drps <- lapply(validation_files, derepFastq)
    dds <- dada(drps, err = err_out, selfConsist = FALSE, multithread = dada2_multithread, verbose = FALSE)
    detail <- getErrors(dds, detailed = TRUE)
    score_model(detail$trans, err_out)
}

make_split <- function(files, seed_offset = 0L) {
    if (length(files) < 3) {
        return(NULL)
    }

    set.seed(1000L + seed_offset)
    shuffled <- sample(files)
    validation_n <- max(1L, floor(length(files) * 0.3))
    validation <- shuffled[seq_len(validation_n)]
    train <- shuffled[-seq_len(validation_n)]

    if (length(train) < 2 || length(validation) < 1) {
        return(NULL)
    }

    list(train = train, validation = validation)
}

candidate_score_summary <- function(files) {
    summaries <- lapply(names(MODEL_DEFS), function(candidate) {
        split_scores <- c()

        for (idx in seq_len(AUTO_SPLITS)) {
            split <- make_split(files, idx)
            if (is.null(split)) {
                break
            }

            score <- tryCatch({
                trained <- learn_model(split$train, candidate, nbases = AUTO_TRAIN_NBASES, randomize = TRUE)
                score_validation(split$validation, trained$err_out)
            }, error = function(e) {
                message("Model ", candidate, " failed on split ", idx, ": ", conditionMessage(e))
                Inf
            })
            split_scores <- c(split_scores, score)
        }

        finite_scores <- split_scores[is.finite(split_scores)]
        data.frame(
            model = candidate,
            splits = length(split_scores),
            valid_splits = length(finite_scores),
            mean_score = if (length(finite_scores)) mean(finite_scores) else Inf,
            stringsAsFactors = FALSE
        )
    })

    do.call(rbind, summaries)
}

choose_models <- function(fwd_files, rev_files, request) {
    forward_q <- sample_quality_values(fwd_files)
    reverse_q <- sample_quality_values(rev_files)
    forward_binned <- qualities_are_binned(forward_q)
    reverse_binned <- qualities_are_binned(reverse_q)
    forward_summary <- if (length(forward_q)) paste(forward_q, collapse = ",") else "NA"
    reverse_summary <- if (length(reverse_q)) paste(reverse_q, collapse = ",") else "NA"

    build_selection <- function(direction, selected_model, selection_reason, binned, quality_values, scores = NULL) {
        list(
            direction = direction,
            requested_model = request,
            selected_model = selected_model,
            selection_reason = selection_reason,
            binned = binned,
            quality_values = quality_values,
            scores = scores
        )
    }

    if (request != "auto") {
        return(list(
            build_selection("forward", request, "user-forced", forward_binned, forward_summary),
            build_selection("reverse", request, "user-forced", reverse_binned, reverse_summary)
        ))
    }

    if (!forward_binned && !reverse_binned) {
        return(list(
            build_selection("forward", "vanilla", "qualities-not-binned", forward_binned, forward_summary),
            build_selection("reverse", "vanilla", "qualities-not-binned", reverse_binned, reverse_summary)
        ))
    }

    forward_scores <- candidate_score_summary(fwd_files)
    reverse_scores <- candidate_score_summary(rev_files)

    paired_scores <- merge(
        forward_scores[, c("model", "valid_splits", "mean_score")],
        reverse_scores[, c("model", "valid_splits", "mean_score")],
        by = "model",
        suffixes = c("_forward", "_reverse")
    )

    viable <- paired_scores[
        is.finite(paired_scores$mean_score_forward) &
        is.finite(paired_scores$mean_score_reverse) &
        paired_scores$valid_splits_forward > 0 &
        paired_scores$valid_splits_reverse > 0,
        ,
        drop = FALSE
    ]

    if (nrow(viable) == 0) {
        shared_model <- "vanilla"
        shared_reason <- "auto-selection-failed-fallback-vanilla"
    } else {
        viable$joint_score <- viable$mean_score_forward + viable$mean_score_reverse
        viable <- viable[order(viable$joint_score, viable$model), , drop = FALSE]
        best <- viable[1, , drop = FALSE]
        vanilla_row <- viable[viable$model == "vanilla", , drop = FALSE]

        shared_model <- "vanilla"
        shared_reason <- "binned-no-clear-improvement"
        if (nrow(vanilla_row) == 0 || !is.finite(vanilla_row$joint_score[[1]])) {
            shared_reason <- "auto-selection-failed-fallback-vanilla"
        } else {
            vanilla_score <- vanilla_row$joint_score[[1]]
            improvement <- (vanilla_score - best$joint_score[[1]]) / vanilla_score
            if (best$model[[1]] == "vanilla") {
                shared_reason <- "binned-shared-vanilla-best"
            } else if (is.finite(improvement) && improvement >= AUTO_MARGIN) {
                shared_model <- best$model[[1]]
                shared_reason <- paste0("binned-shared-auto-selected-", shared_model)
            }
        }
    }

    message(
        "shared: request=", request,
        " forward_binned=", forward_binned,
        " reverse_binned=", reverse_binned,
        " selected=", shared_model,
        " reason=", shared_reason
    )

    list(
        build_selection("forward", shared_model, shared_reason, forward_binned, forward_summary, forward_scores),
        build_selection("reverse", shared_model, shared_reason, reverse_binned, reverse_summary, reverse_scores)
    )
}

write_metadata <- function(path, metadata_rows) {
    header <- c(
        "direction",
        "requested_model",
        "selected_model",
        "selection_reason",
        "qualities_binned",
        "quality_values",
        "candidate_scores"
    )

    lines <- c(paste(header, collapse = "\t"))
    for (row in metadata_rows) {
        candidate_scores <- "NA"
        if (!is.null(row$scores)) {
            candidate_scores <- paste(
                apply(row$scores, 1, function(entry) {
                    sprintf(
                        "%s:%s:%s",
                        entry[["model"]],
                        entry[["valid_splits"]],
                        format(as.numeric(entry[["mean_score"]]), digits = 6, scientific = FALSE)
                    )
                }),
                collapse = ";"
            )
        }

        fields <- c(
            row$direction,
            row$requested_model,
            row$selected_model,
            row$selection_reason,
            ifelse(row$binned, "yes", "no"),
            row$quality_values,
            candidate_scores
        )
        lines <- c(lines, paste(fields, collapse = "\t"))
    }

    writeLines(lines, path)
}

fwd <- list_filtered_files("_R1_filtered.fq.gz")
rev <- list_filtered_files("_R2_filtered.fq.gz")

if (length(fwd) == 0 || length(rev) == 0) {
    stop("No filtered forward/reverse FASTQ files found for error learning")
}

request <- normalize_request(loess_model_arg)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

selections <- choose_models(fwd, rev, request)
forward_selection <- selections[[1]]
reverse_selection <- selections[[2]]

suppressWarnings({
    final_nbases <- if (bigdata_mode) BIGDATA_LEARN_NBASES else NULL
    err_fwd <- learn_model(fwd, forward_selection$selected_model, nbases = final_nbases, randomize = TRUE)
    err_rev <- learn_model(rev, reverse_selection$selected_model, nbases = final_nbases, randomize = TRUE)

    saveRDS(err_fwd, file.path(output_dir, "err_forward_reads.rds"))
    saveRDS(err_rev, file.path(output_dir, "err_reverse_reads.rds"))
})

write_metadata(file.path(output_dir, "model_selection.tsv"), list(
    forward_selection,
    reverse_selection
))

options(warn = 0)

pdf(file.path(output_dir, "err_forward_reads.pdf"))
plotErrors(err_fwd, nominalQ = TRUE)
dev.off()

pdf(file.path(output_dir, "err_reverse_reads.pdf"))
plotErrors(err_rev, nominalQ = TRUE)
dev.off()
