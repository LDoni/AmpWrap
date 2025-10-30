#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
# load  data
seqtab <- readRDS(input)

#remove chimeras
seqtab_nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = TRUE)

saveRDS(seqtab_nochim, output)

options(warn=0)
