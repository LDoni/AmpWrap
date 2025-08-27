#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
output <- args[2]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
# Carica i dati
merged <- readRDS(input)

# Rimuovi chimere
seqtab <- makeSequenceTable(merged)
seqtab_nochim <- removeBimeraDenovo(seqtab, method = "consensus", multithread = TRUE)

# Salva dati senza chimere
saveRDS(seqtab_nochim, output)

options(warn=0)
