#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input <- args[1]
silva_db <- args[2]
output_dir <- args[3]
thread_count_arg <- if (length(args) >= 4) args[4] else "1"
species_db <- if (length(args) >= 5) args[5] else "NONE"
filter_organelle <- if (length(args) >= 6) tolower(args[6]) %in% c("true", "1", "yes") else FALSE
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(biomformat))
suppressPackageStartupMessages(library(phyloseq))
suppressPackageStartupMessages(library(Biostrings))

normalize_sample_name <- function(x) {
  x <- sub("_R1_filtered\\.fq\\.gz$", "", x)
  x <- sub("_R2_filtered\\.fq\\.gz$", "", x)
  x <- sub("_R1_filtered\\.fastq\\.gz$", "", x, ignore.case = TRUE)
  x <- sub("_R2_filtered\\.fastq\\.gz$", "", x, ignore.case = TRUE)
  x
}

filter_organelle_taxa <- function(ps) {
  tax_df <- as.data.frame(tax_table(ps), stringsAsFactors = FALSE)
  matches <- apply(tax_df, 1, function(row) {
    values <- tolower(trimws(as.character(row)))
    any(values %in% c("mitochondria", "chloroplast"))
  })
  phyloseq::prune_taxa(!matches, ps)
}

write_filtered_outputs <- function(ps_filtered, output_dir) {
  otu <- as(otu_table(ps_filtered), "matrix")
  if (taxa_are_rows(ps_filtered)) {
    otu_out <- otu
  } else {
    otu_out <- t(otu)
  }
  tax_out <- as(tax_table(ps_filtered), "matrix")

  write.table(
    otu_out,
    file.path(output_dir, "ASVs_counts_no_organelle.tsv"),
    sep = "\t",
    row.names = TRUE,
    quote = FALSE
  )
  write.table(
    tax_out,
    file.path(output_dir, "ASVs_taxonomy_no_organelle.tsv"),
    sep = "\t",
    row.names = TRUE,
    quote = FALSE
  )

  biom_obj_filtered <- biomformat::make_biom(
    data = otu_out,
    observation_metadata = tax_out
  )
  biomformat::write_biom(biom_obj_filtered, file.path(output_dir, "ASVs_no_organelle.biom"))
}

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
  if (threads <= 1L) FALSE else TRUE
}

dada2_multithread <- configure_parallelism(thread_count_arg)

#load chimeres
seqtab_nochim <- readRDS(input)
rownames(seqtab_nochim) <- normalize_sample_name(rownames(seqtab_nochim))

# Assign taxonomy
taxa <- assignTaxonomy(seqtab_nochim, silva_db, multithread = dada2_multithread)
if (!identical(species_db, "NONE")) {
  taxa <- addSpecies(taxa, species_db)
}

asv_seqs <- colnames(seqtab_nochim)

asv_headers <- vector(dim(seqtab_nochim)[2], mode = "character")
for (i in seq_along(asv_seqs)) {
  asv_headers[i] <- paste(">ASV", i, sep = "_")
}

#write fasta
write(c(rbind(asv_headers, asv_seqs)), file.path(output_dir, "ASVs.fa"))
asv_tab <- t(seqtab_nochim)
row.names(asv_tab) <- sub(">", "", asv_headers)
write.table(asv_tab, file.path(output_dir, "ASVs_counts.tsv"), sep = "\t", row.names = TRUE, quote = FALSE)

# tax
asv_tax <- taxa
ranks <- c("domain", "phylum", "class", "order", "family", "genus")
if (ncol(asv_tax) >= 7) {
  ranks <- c(ranks, "species")
}
asv_tax[startsWith(asv_tax, "unclassified_")] <- NA
colnames(asv_tax) <- ranks[seq_len(ncol(asv_tax))]

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
if (filter_organelle) {
  ps_filtered <- filter_organelle_taxa(ps)
  saveRDS(ps_filtered, file.path(output_dir, "phyloseq_object_no_organelle.rds"))
  write_filtered_outputs(ps_filtered, output_dir)
}
options(warn=0)
