#!/usr/bin/env Rscript
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(DECIPHER))
suppressPackageStartupMessages(library(Biostrings))
suppressPackageStartupMessages(library(biomformat))
suppressPackageStartupMessages(library(phyloseq))
# load args
args <- commandArgs(trailingOnly = TRUE)
if (!(length(args) %in% c(3, 4))) {
  stop("Usage: Rscript dada2_assign_taxonomy.R <no_chimera_asvs> <silva_db> <output_dir> [threads]")
}

no_chimera_asvs <- args[1]
silva_db <- args[2]
output_dir <- args[3]
thread_count_arg <- if (length(args) >= 4) args[4] else "1"

configure_parallelism <- function(value) {
  threads <- suppressWarnings(as.integer(value))
  if (is.na(threads) || threads < 1) {
    threads <- 1L
  }
  Sys.setenv(
    RCPP_PARALLEL_NUM_THREADS = threads,
    OMP_NUM_THREADS = threads,
    OPENBLAS_NUM_THREADS = threads,
    MKL_NUM_THREADS = threads,
    VECLIB_MAXIMUM_THREADS = threads,
    BLIS_NUM_THREADS = threads
  )
  if (requireNamespace("RcppParallel", quietly = TRUE)) {
    RcppParallel::setThreadOptions(numThreads = threads)
  }
  threads
}

decipher_processors <- configure_parallelism(thread_count_arg)

seqtab.nochim <- readRDS(no_chimera_asvs)

load(silva_db)

# Assign tax
dna <- DNAStringSet(getSequences(seqtab.nochim))
tax_info <- IdTaxa(test = dna, trainingSet = trainingSet, strand = "both", processors = decipher_processors)

# header ASVs
asv_seqs <- colnames(seqtab.nochim)
asv_headers <- vector(dim(seqtab.nochim)[2], mode = "character")
for (i in seq_along(asv_seqs)) {
  asv_headers[i] <- paste(">ASV", i, sep = "_")
}

# ASVs FASTA
asv_fasta <- c(rbind(asv_headers, asv_seqs))
write(asv_fasta, file.path(output_dir, "ASVs.fa"))

# Table ASVs 
asv_tab <- t(seqtab.nochim)
row.names(asv_tab) <- sub(">", "", asv_headers)
write.table(asv_tab, file.path(output_dir, "ASVs_counts.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)

# tax table
ranks <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")

asv_tax <- t(sapply(tax_info, function(x) {
  taxa <- rep(NA, length(ranks))
  full_tax <- unlist(strsplit(x$taxon, ";\\s*"))  # split su "; "
  full_tax <- full_tax[full_tax != "Root"]
  taxa[seq_along(full_tax)] <- full_tax[seq_along(full_tax)]
  taxa[startsWith(taxa, "unclassified_")] <- NA
  return(taxa)
}))

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
