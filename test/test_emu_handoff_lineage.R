#!/usr/bin/env Rscript

setClass("Snakemake", slots = c(log = "list", params = "list"))

script_path <- normalizePath(file.path("ampwrap", "scripts", "emu_handoff.R"))
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)

emu_dir <- tempfile("emu_lineage_")
dir.create(emu_dir)

writeLines(
  c(
    "tax_id\tabundance\tlineage",
    paste(
      "1",
      "0.75",
      "Bacteria;Firmicutes;;Lactobacillales;Streptococcaceae;Streptococcus;Streptococcus thermophilus",
      sep = "\t"
    )
  ),
  file.path(emu_dir, "sample_rel-abundance.tsv")
)

snakemake <- new(
  "Snakemake",
  log = list(file.path(emu_dir, "emu_phyloseq.log")),
  params = list(emu_dir = emu_dir)
)

source(script_path, local = FALSE)
setwd(old_wd)

ps <- readRDS(file.path(emu_dir, "emu_phyloseq.rds"))
taxonomy <- as(phyloseq::tax_table(ps), "matrix")

stopifnot(identical(taxonomy[1, "superkingdom"], "Bacteria"))
stopifnot(identical(taxonomy[1, "phylum"], "Firmicutes"))
stopifnot(identical(taxonomy[1, "class"], ""))
stopifnot(identical(taxonomy[1, "order"], "Lactobacillales"))
stopifnot(identical(taxonomy[1, "family"], "Streptococcaceae"))
stopifnot(identical(taxonomy[1, "genus"], "Streptococcus"))
stopifnot(identical(taxonomy[1, "species"], "Streptococcus thermophilus"))

cat("EMU lineage parsing preserves empty internal ranks\n")
