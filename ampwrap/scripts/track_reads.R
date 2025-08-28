#!/usr/bin/env Rscript
options(warn=-1)
# Carica i pacchetti necessari
suppressPackageStartupMessages(library(dada2))

# Funzione per calcolare il numero di sequenze uniche
getN <- function(x) sum(getUniques(x))

# Leggi gli argomenti dalla command line
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 6) {
  stop("Usage: Rscript track_reads.R <filter_summary.tsv> <dada_fwd_rds> <dada_rev_rds> <merged_rds> <seqtab_nochim_rds> <output_csv>")
}

# Assegna gli argomenti a variabili
filter_summary.tsv <- args[1]
dada_fwd_rds <- args[2]
dada_rev_rds <- args[3]
merged_rds <- args[4]
seqtab_nochim_rds <- args[5]
output_tsv <- args[6]

# Carica i dati
#out <- read.csv(filter_summary.csv, row.names = 1)
out <- read.table(filter_summary.tsv, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
rownames(out) <- out$sample
out$sample <- NULL

dada_fwd <- readRDS(dada_fwd_rds)
dada_rev <- readRDS(dada_rev_rds)
merged <- readRDS(merged_rds)
seqtab.nochim <- readRDS(seqtab_nochim_rds)

# Calcola il tracking
track <- cbind(out,
               dadaF = sapply(dada_fwd, getN),
               dadaR = sapply(dada_rev, getN),
               merged = sapply(merged, getN),
               nonchim = rowSums(seqtab.nochim),
               total_retained = round(rowSums(seqtab.nochim) / out[, 1] * 100, 1))

# Riporta la colonna "sample"
track <- cbind(sample = rownames(track), track)

# Salva il tracking in un file TSV
write.table(track, output_tsv, row.names = FALSE, sep = "\t", quote = FALSE)
options(warn=0)
