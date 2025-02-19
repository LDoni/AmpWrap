#!/usr/bin/env Rscript

# Carica i pacchetti necessari
suppressPackageStartupMessages(library(dada2))

# Leggi gli argomenti dalla command line
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("Usage: Rscript script.R <no_chimera_asvs> <silva_db> <output_dir>")
}

input <- args[1]
silva_db <- args[2]
output_dir <- args[3]

# Logging
log <- function(msg) {
  cat(paste0("[", Sys.time(), "] ", msg, "\n"))
}

# Carica dati senza chimere
seqtab_nochim <- readRDS(input)

# Assegna la tassonomia
taxa <- assignTaxonomy(seqtab_nochim, silva_db, multithread = TRUE)

log("Taxonomy assignment completed.")

# Genera l'header delle ASVs
asv_seqs <- colnames(seqtab_nochim)
asv_headers <- paste0(">ASV_", seq_len(ncol(seqtab_nochim)))

# Scrivi le sequenze ASVs in un file FASTA
asv_fasta <- c(rbind(asv_headers, asv_seqs))
write(asv_fasta, file.path(output_dir, "ASVs.fa"))

# Tabella delle ASVs (conteggi)
asv_tab <- t(seqtab_nochim)
row.names(asv_tab) <- sub(">", "", asv_headers)
write.csv(asv_tab, file.path(output_dir, "ASVs_counts.csv"), row.names = TRUE, quote = FALSE)

# Tabella della tassonomia
write.csv(taxa, file.path(output_dir, "ASVs_taxonomy.csv"), row.names = TRUE, quote = FALSE)

# Salva il tracking delle letture
getN <- function(x) sum(getUniques(x))
track <- cbind(
  dada2_input = rowSums(seqtab_nochim),
  filtered = rowSums(seqtab_nochim),
  nonchim = rowSums(seqtab_nochim)
)
write.csv(track, file.path(output_dir, "read-count-tracking.csv"), row.names = TRUE)

log("Read count tracking saved.")
log("All files have been written successfully.")
