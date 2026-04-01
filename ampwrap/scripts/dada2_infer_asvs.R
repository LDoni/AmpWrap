#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
err_fwd_file <- args[2]
err_rev_file <- args[3]
output <- args[4]
thread_count_arg <- if (length(args) >= 5) args[5] else "1"

options(warn = -1)
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

sample_name_from_file <- function(path, direction) {
  sub(paste0("_", direction, "_filtered\\.fq\\.gz$"), "", basename(path))
}

fwd <- list.files(input_dir, pattern = "_R1_filtered.fq.gz", full.names = TRUE)
rev <- list.files(input_dir, pattern = "_R2_filtered.fq.gz", full.names = TRUE)

fwd <- fwd[order(basename(fwd))]
rev <- rev[order(basename(rev))]

fwd_names <- vapply(fwd, sample_name_from_file, character(1), direction = "R1")
rev_names <- vapply(rev, sample_name_from_file, character(1), direction = "R2")

sample_names <- intersect(fwd_names, rev_names)
if (length(sample_names) == 0) {
  stop("No matched filtered forward/reverse sample pairs found for ASV inference")
}

fwd <- fwd[match(sample_names, fwd_names)]
rev <- rev[match(sample_names, rev_names)]
names(fwd) <- sample_names
names(rev) <- sample_names

err_fwd <- readRDS(err_fwd_file)
err_rev <- readRDS(err_rev_file)

derep_fwd <- derepFastq(fwd)
derep_rev <- derepFastq(rev)

dada_fwd <- dada(derep_fwd, err = err_fwd, multithread = dada2_multithread)
dada_rev <- dada(derep_rev, err = err_rev, multithread = dada2_multithread)

merged <- mergePairs(dada_fwd, derep_fwd, dada_rev, derep_rev, trimOverhang = TRUE)

saveRDS(merged, output)
saveRDS(dada_fwd, file.path(dirname(output), "dada_fwd.rds"))
saveRDS(dada_rev, file.path(dirname(output), "dada_rev.rds"))

options(warn = 0)
