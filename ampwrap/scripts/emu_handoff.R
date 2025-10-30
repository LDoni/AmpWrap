#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(phyloseq)
  library(biomformat)
})

emu_dir <- snakemake@params[["emu_dir"]]
setwd(emu_dir)

cat("Directory EMU:", emu_dir, "\n")

list_file <- list.files(pattern = "_rel-abundance.tsv$")

if (length(list_file) == 0) stop("Nessun file '_rel-abundance.tsv' trovato!")

combined_df <- list_file %>%
  setNames(nm = gsub("^combined\\.trimmed_|_rel-abundance\\.tsv$", "", .)) %>%
  map_dfr(~ {
    df <- read.delim(.x, header = TRUE, sep = "\t", stringsAsFactors = FALSE)
    df <- df[, c("superkingdom", "phylum", "class", "order", "family", "genus", "species", "abundance")]
    df$superkingdom <- gsub("\\[|\\]", "", df$superkingdom)
    df$phylum        <- gsub("\\[|\\]", "", df$phylum)
    df$class         <- gsub("\\[|\\]", "", df$class)
    df$order         <- gsub("\\[|\\]", "", df$order)
    df$family        <- gsub("\\[|\\]", "", df$family)
    df$genus         <- gsub("\\[|\\]", "", df$genus)
    df$species       <- gsub("\\[|\\]", "", df$species)
    df$sample <- gsub("^combined\\.trimmed_|_rel-abundance\\.tsv$", "", .x)
    df
  })



combined_df_clean <- combined_df %>%
  filter(!is.na(superkingdom) & superkingdom != "") %>%
  mutate(abundance = as.numeric(unlist(abundance)))


combined_df_clean <- combined_df_clean %>%
  unite(
    taxon, superkingdom, phylum, class, order, family, genus, species,
    sep = ";", remove = FALSE
  ) %>%
  group_by(taxon) %>%
  mutate(taxa_id = paste0("OTU_", cur_group_id())) %>%
  ungroup()

otu_df <- combined_df_clean %>%
  select(taxa_id, sample, abundance) %>%
  pivot_wider(
    names_from = sample,
    values_from = abundance,
    values_fill = list(abundance = 0)
  ) %>%
  column_to_rownames("taxa_id")

otu_mat <- as.matrix(otu_df)
OTU <- otu_table(otu_mat, taxa_are_rows = TRUE)

TAX <- combined_df_clean %>%
  distinct(taxa_id, .keep_all = TRUE) %>%
  select(taxa_id, superkingdom, phylum, class, order, family, genus, species) %>%
  column_to_rownames("taxa_id")

TAX <- tax_table(as.matrix(TAX))

ps <- phyloseq(OTU, TAX)

saveRDS(ps, file = "emu_phyloseq.rds")

biom_out <- make_biom(data = otu_table(ps), observation_metadata = tax_table(ps))
write_biom(biom_out, "emu_abundance.biom")
