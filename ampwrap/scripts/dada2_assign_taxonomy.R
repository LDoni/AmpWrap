#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
silva_db <- args[2]
output_dir <- args[3]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))

# Carica dati senza chimere
seqtab_nochim <- readRDS(input)

# Assegna la tassonomia
taxa <- assignTaxonomy(seqtab_nochim, silva_db, multithread = TRUE)

# Salva risultati
asv_seqs <- colnames(seqtab_nochim)
#asv_headers <- paste0(">ASV_", seq_len(ncol(seqtab_nochim)))

asv_headers <- vector(dim(seqtab_nochim)[2], mode = "character")
for (i in seq_along(asv_seqs)) {
  asv_headers[i] <- paste(">ASV", i, sep = "_")
}

# Salva ASVs
write(c(rbind(asv_headers, asv_seqs)), file.path(output_dir, "ASVs.fa"))

# Salva conteggio ASVs
asv_tab <- t(seqtab_nochim)
row.names(asv_tab) <- sub(">", "", asv_headers)
colnames(asv_tab) <- sapply(colnames(asv_tab), function(x) strsplit(x, "_")[[1]][1])
write.table(asv_tab, file.path(output_dir, "ASVs_counts.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)

# Salva tassonomia
ranks <- c("domain", "phylum", "class", "order", "family", "genus")




# Sostituisci "unclassified_" con NA
asv_tax <- taxa
asv_tax[startsWith(asv_tax, "unclassified_")] <- NA

# Assicurati che le colonne abbiano i nomi corretti
colnames(asv_tax) <- ranks

# Assegna gli ASV come nomi delle righe
rownames(asv_tax) <- gsub(pattern = ">", replacement = "", x = asv_headers)

# Salva la tabella della tassonomia
write.table(asv_tax, file.path(output_dir, "ASVs_taxonomy.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)
options(warn=0)
