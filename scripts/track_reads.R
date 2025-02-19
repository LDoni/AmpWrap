#!/usr/bin/env Rscript

# Carica i pacchetti necessari
suppressPackageStartupMessages(library(dada2))

# Funzione per calcolare il numero di sequenze uniche
getN <- function(x) sum(getUniques(x))

# Leggi gli argomenti dalla command line
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 6) {
  stop("Usage: Rscript track_reads.R <filter_summary.csv> <dada_fwd_rds> <dada_rev_rds> <merged_rds> <seqtab_nochim_rds> <output_csv>")
}

# Assegna gli argomenti a variabili
filter_summary.csv <- args[1]
dada_fwd_rds <- args[2]
dada_rev_rds <- args[3]
merged_rds <- args[4]
seqtab_nochim_rds <- args[5]
output_csv <- args[6]

# Carica i dati
out <- read.csv(filter_summary.csv, row.names = 1)
dada_fwd <- readRDS(dada_fwd_rds)
dada_rev <- readRDS(dada_rev_rds)
merged <- readRDS(merged_rds)
seqtab.nochim <- readRDS(seqtab_nochim_rds)

# Calcola il tracking
track <- cbind(out, sapply(dada_fwd, getN), sapply(dada_rev, getN), sapply(merged, getN), rowSums(seqtab.nochim), 
               round(rowSums(seqtab.nochim) / out[, 1] * 100, 1))

# Assegna nomi alle colonne e righe
colnames(track) <- c("input", "filtered", "dadaF", "dadaR", "merged", "nonchim", "total_retained")

track <- cbind(sample = rownames(track), track)

# Salva il tracking in un file TSV
write.table(track, output_csv, row.names = FALSE, sep = "\t", quote = FALSE)
