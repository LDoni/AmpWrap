#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(phyloseq)
  library(biomformat)
})

if (length(snakemake@log) > 0) {
  log_file <- snakemake@log[[1]]
  dir.create(dirname(log_file), recursive = TRUE, showWarnings = FALSE)
  log_con <- file(log_file, open = "wt")
  sink(log_con, type = "output")
  sink(log_con, type = "message")
  on.exit({
    sink(type = "message")
    sink(type = "output")
    close(log_con)
  }, add = TRUE)
}

emu_dir <- snakemake@params[["emu_dir"]]
setwd(emu_dir)

cat("Directory EMU:", emu_dir, "\n")

list_file <- list.files(pattern = "_rel-abundance.tsv$")

if (length(list_file) == 0) stop("Nessun file '_rel-abundance.tsv' trovato!")

sample_name_from_file <- function(path) {
  gsub("(^combined\\.trimmed_|-(nanofilt|scrubbed)_rel-abundance\\.tsv$|_rel-abundance\\.tsv$)", "", path)
}

clean_rank <- function(x) {
  x <- gsub("\\[|\\]", "", x)
  x[is.na(x)] <- ""
  x
}

taxonomy_cols <- c("superkingdom", "phylum", "class", "order", "family", "genus", "species")

split_lineage <- function(lineage) {
  ranks <- strsplit(lineage, ";", fixed = TRUE)
  ranks <- lapply(ranks, function(x) {
    x <- x[x != ""]
    length(x) <- length(taxonomy_cols)
    x[is.na(x)] <- ""
    x
  })
  taxonomy <- as.data.frame(do.call(rbind, ranks), stringsAsFactors = FALSE)
  names(taxonomy) <- taxonomy_cols
  taxonomy
}

frames <- lapply(list_file, function(path) {
  df <- read.delim(path, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

  if (all(taxonomy_cols %in% names(df))) {
    df <- df[, c(taxonomy_cols, "abundance")]
  } else if ("lineage" %in% names(df)) {
    taxonomy <- split_lineage(df$lineage)
    df <- cbind(taxonomy, abundance = df$abundance)
  } else {
    stop(
      "Unsupported EMU abundance format in ", path,
      ". Expected either taxonomy columns or a lineage column. Found: ",
      paste(names(df), collapse = ", ")
    )
  }

  for (col in taxonomy_cols) {
    df[[col]] <- clean_rank(df[[col]])
  }
  df$sample <- sample_name_from_file(path)
  df
})

combined_df <- do.call(rbind, frames)
combined_df <- combined_df[combined_df$superkingdom != "", , drop = FALSE]
combined_df$abundance <- as.numeric(combined_df$abundance)
combined_df$taxon <- apply(
  combined_df[, c("superkingdom", "phylum", "class", "order", "family", "genus", "species"), drop = FALSE],
  1,
  paste,
  collapse = ";"
)

taxa_levels <- unique(combined_df$taxon)
taxa_ids <- setNames(sprintf("OTU_%d", seq_along(taxa_levels)), taxa_levels)
combined_df$taxa_id <- unname(taxa_ids[combined_df$taxon])

otu_df <- xtabs(abundance ~ taxa_id + sample, data = combined_df)
otu_mat <- matrix(
  as.numeric(otu_df),
  nrow = nrow(otu_df),
  ncol = ncol(otu_df),
  dimnames = dimnames(otu_df)
)
OTU <- phyloseq::otu_table(otu_mat, taxa_are_rows = TRUE)

taxonomy_df <- combined_df[!duplicated(combined_df$taxa_id), c("taxa_id", "superkingdom", "phylum", "class", "order", "family", "genus", "species")]
rownames(taxonomy_df) <- taxonomy_df$taxa_id
taxonomy_df$taxa_id <- NULL
TAX <- phyloseq::tax_table(as.matrix(taxonomy_df))

ps <- phyloseq::phyloseq(OTU, TAX)

saveRDS(ps, file = "emu_phyloseq.rds")

biom_out <- biomformat::make_biom(data = phyloseq::otu_table(ps), observation_metadata = phyloseq::tax_table(ps))
biomformat::write_biom(biom_out, "emu_abundance.biom")
