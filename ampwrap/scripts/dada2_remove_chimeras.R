#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]
length_mode <- if (length(args) >= 3 && nzchar(args[3])) args[3] else "off"
length_min <- if (length(args) >= 4 && nzchar(args[4])) as.integer(args[4]) else NA_integer_
length_max <- if (length(args) >= 5 && nzchar(args[5])) as.integer(args[5]) else NA_integer_
amplicon_length <- if (length(args) >= 6 && nzchar(args[6])) as.integer(args[6]) else NA_integer_
thread_count_arg <- if (length(args) >= 7) args[7] else "1"
metadata_path <- if (length(args) >= 8 && nzchar(args[8])) args[8] else ""
options(warn=-1)
suppressPackageStartupMessages(library(dada2))

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
# load  data
seqtab <- readRDS(input)

#remove chimeras
seqtab_nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = dada2_multithread)
lengths_before <- nchar(colnames(seqtab_nochim))
mode_length <- if (length(lengths_before)) {
  as.integer(names(sort(table(lengths_before), decreasing = TRUE))[1])
} else {
  NA_integer_
}
warning_message <- ""
asvs_before <- ncol(seqtab_nochim)

if (length_mode == "auto" && !is.na(mode_length)) {
  length_min <- max(1L, mode_length - 10L)
  length_max <- mode_length + 10L
  if (!is.na(amplicon_length) && abs(mode_length - amplicon_length) > 10L) {
    warning_message <- sprintf(
      "Observed dominant ASV length (%d) differs from expected amplicon length (%d) by more than 10 bp.",
      mode_length,
      amplicon_length
    )
  }
}

if (length_mode %in% c("auto", "range") && !is.na(length_min) && !is.na(length_max)) {
  seq_lengths <- nchar(colnames(seqtab_nochim))
  keep <- seq_lengths >= length_min & seq_lengths <= length_max
  seqtab_nochim <- seqtab_nochim[, keep, drop = FALSE]
}

saveRDS(seqtab_nochim, output)

if (nzchar(metadata_path)) {
  metadata <- data.frame(
    mode = length_mode,
    dominant_length = mode_length,
    expected_amplicon_length = amplicon_length,
    applied_min = if (is.na(length_min)) "" else length_min,
    applied_max = if (is.na(length_max)) "" else length_max,
    asvs_before = asvs_before,
    asvs_after = ncol(seqtab_nochim),
    warning = warning_message,
    stringsAsFactors = FALSE
  )
  write.table(metadata, metadata_path, sep = "\t", row.names = FALSE, quote = FALSE)
}

options(warn=0)
