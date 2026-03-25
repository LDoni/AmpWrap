#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]
length_min <- if (length(args) >= 3 && nzchar(args[3])) as.integer(args[3]) else NA_integer_
length_max <- if (length(args) >= 4 && nzchar(args[4])) as.integer(args[4]) else NA_integer_
thread_count_arg <- if (length(args) >= 5) args[5] else "1"
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

if (!is.na(length_min) && !is.na(length_max)) {
  seq_lengths <- nchar(colnames(seqtab_nochim))
  keep <- seq_lengths >= length_min & seq_lengths <= length_max
  seqtab_nochim <- seqtab_nochim[, keep, drop = FALSE]
}

saveRDS(seqtab_nochim, output)

options(warn=0)
