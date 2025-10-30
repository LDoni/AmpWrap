#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
#load data
merged <- readRDS(input)

# SAV table
seqtab <- makeSequenceTable(merged)

saveRDS(seqtab, output)

options(warn=0)
