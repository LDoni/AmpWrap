#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]
length_min <- if (length(args) >= 3 && nzchar(args[3])) as.integer(args[3]) else NA_integer_
length_max <- if (length(args) >= 4 && nzchar(args[4])) as.integer(args[4]) else NA_integer_
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
# load  data
seqtab <- readRDS(input)

#remove chimeras
seqtab_nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = TRUE)

if (!is.na(length_min) && !is.na(length_max)) {
  seq_lengths <- nchar(colnames(seqtab_nochim))
  keep <- seq_lengths >= length_min & seq_lengths <= length_max
  seqtab_nochim <- seqtab_nochim[, keep, drop = FALSE]
}

saveRDS(seqtab_nochim, output)

options(warn=0)
