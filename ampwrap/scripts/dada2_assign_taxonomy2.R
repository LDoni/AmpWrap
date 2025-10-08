#!/usr/bin/env Rscript
options(warn=-1)
# Carica i pacchetti necessari
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(DECIPHER))
suppressPackageStartupMessages(library(Biostrings))
suppressPackageStartupMessages(library(biomformat))
suppressPackageStartupMessages(library(phyloseq))
# Leggi gli argomenti dalla command line
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("Usage: Rscript dada2_assign_taxonomy.R <no_chimera_asvs> <silva_db> <output_dir>")
}

no_chimera_asvs <- args[1]
silva_db <- args[2]
output_dir <- args[3]

seqtab.nochim <- readRDS(no_chimera_asvs)

load(silva_db)

# Assegna la tassonomia
dna <- DNAStringSet(getSequences(seqtab.nochim))
tax_info <- IdTaxa(test = dna, trainingSet = trainingSet, strand = "both", processors = NULL)

# Genera l'header delle ASVs
asv_seqs <- colnames(seqtab.nochim)
asv_headers <- vector(dim(seqtab.nochim)[2], mode = "character")
for (i in seq_along(asv_seqs)) {
  asv_headers[i] <- paste(">ASV", i, sep = "_")
}

# Scrivi le sequenze ASVs in un file FASTA
asv_fasta <- c(rbind(asv_headers, asv_seqs))
write(asv_fasta, file.path(output_dir, "ASVs.fa"))

# Tabella delle ASVs (conteggi)
asv_tab <- t(seqtab.nochim)
row.names(asv_tab) <- sub(">", "", asv_headers)
colnames(asv_tab) <- sapply(colnames(asv_tab), function(x) strsplit(x, "_")[[1]][1])
write.table(asv_tab, file.path(output_dir, "ASVs_counts.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)

# Tabella della tassonomia
ranks <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")

# Sostituisci "unclassified_" con NA

asv_tax <- t(sapply(tax_info, function(x) {
  taxa <- rep(NA, length(ranks))
  full_tax <- unlist(strsplit(x$taxon, ";\\s*"))  # split su "; "
  full_tax <- full_tax[full_tax != "Root"]
  taxa[seq_along(full_tax)] <- full_tax[seq_along(full_tax)]
  taxa[startsWith(taxa, "unclassified_")] <- NA
  return(taxa)
}))





# Assicurati che le colonne abbiano i nomi corretti
colnames(asv_tax) <- ranks

# Assegna gli ASV come nomi delle righe
rownames(asv_tax) <- gsub(pattern = ">", replacement = "", x = asv_headers)

# Salva la tabella della tassonomia
write.table(asv_tax, file.path(output_dir, "ASVs_taxonomy.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)


# Crea oggetto BIOM
# Assicurati che i nomi delle righe siano consistenti
rownames(asv_tab) <- gsub(pattern = ">", replacement = "", x = asv_headers)
rownames(asv_tax) <- rownames(asv_tab)

# Crea oggetto biom
biom_obj <- biomformat::make_biom(
  data = asv_tab,
  observation_metadata = asv_tax
)

# Salva file BIOM
biomformat::write_biom(biom_obj, file.path(output_dir, "ASVs.biom"))

# Crea oggetto phyloseq
ps <- phyloseq(
  otu_table(asv_tab, taxa_are_rows = TRUE),
  tax_table(asv_tax)
)

# Salva oggetto phyloseq
saveRDS(ps, file.path(output_dir, "phyloseq_object.rds"))                            
options(warn=0)




                            
options(warn=0)
