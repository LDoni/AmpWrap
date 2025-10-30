#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
silva_db <- args[2]
output_dir <- args[3]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(biomformat))
suppressPackageStartupMessages(library(phyloseq))
suppressPackageStartupMessages(library(Biostrings))

#load chimeres
seqtab_nochim <- readRDS(input)

# Assign taxonomy
taxa <- assignTaxonomy(seqtab_nochim, silva_db, multithread = TRUE)

asv_seqs <- colnames(seqtab_nochim)

asv_headers <- vector(dim(seqtab_nochim)[2], mode = "character")
for (i in seq_along(asv_seqs)) {
  asv_headers[i] <- paste(">ASV", i, sep = "_")
}

#write fasta
write(c(rbind(asv_headers, asv_seqs)), file.path(output_dir, "ASVs.fa"))
asv_tab <- t(seqtab_nochim)
row.names(asv_tab) <- sub(">", "", asv_headers)
colnames(asv_tab) <- sapply(colnames(asv_tab), function(x) strsplit(x, "_")[[1]][1])
write.table(asv_tab, file.path(output_dir, "ASVs_counts.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)

# tax
ranks <- c("domain", "supergroup", "phylum", "class", "order", "family", "genus", "species")

asv_tax <- taxa
asv_tax[startsWith(asv_tax, "unclassified_")] <- NA
colnames(asv_tax) <- ranks

rownames(asv_tax) <- gsub(pattern = ">", replacement = "", x = asv_headers)

write.table(asv_tax, file.path(output_dir, "ASVs_taxonomy.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)



#  BIOM obj
rownames(asv_tab) <- gsub(pattern = ">", replacement = "", x = asv_headers)
rownames(asv_tax) <- rownames(asv_tab)

biom_obj <- biomformat::make_biom(
  data = asv_tab,
  observation_metadata = asv_tax
)
biomformat::write_biom(biom_obj, file.path(output_dir, "ASVs.biom"))

# phyloseq obj
ps <- phyloseq(
  otu_table(asv_tab, taxa_are_rows = TRUE),
  tax_table(asv_tax)
)
saveRDS(ps, file.path(output_dir, "phyloseq_object.rds"))                            
options(warn=0)
