#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
err_fwd_file <- args[2]
err_rev_file <- args[3]
output <- args[4]

options(warn = -1)
suppressPackageStartupMessages(library(dada2))

sample_name_from_file <- function(path, direction) {
  sub(paste0("_", direction, "_filtered\\.fq\\.gz$"), "", basename(path))
}

fwd <- list.files(input_dir, pattern = "_R1_filtered.fq.gz", full.names = TRUE)
rev <- list.files(input_dir, pattern = "_R2_filtered.fq.gz", full.names = TRUE)

fwd <- fwd[order(basename(fwd))]
rev <- rev[order(basename(rev))]

fwd_names <- vapply(fwd, sample_name_from_file, character(1), direction = "R1")
rev_names <- vapply(rev, sample_name_from_file, character(1), direction = "R2")

sample_names <- intersect(fwd_names, rev_names)
if (length(sample_names) == 0) {
  stop("No matched filtered forward/reverse sample pairs found for ASV inference")
}

fwd <- fwd[match(sample_names, fwd_names)]
rev <- rev[match(sample_names, rev_names)]
names(fwd) <- sample_names
names(rev) <- sample_names

err_fwd <- readRDS(err_fwd_file)
err_rev <- readRDS(err_rev_file)

dada_fwd <- vector("list", length(sample_names))
dada_rev <- vector("list", length(sample_names))
merged <- vector("list", length(sample_names))
names(dada_fwd) <- sample_names
names(dada_rev) <- sample_names
names(merged) <- sample_names

for (sam in sample_names) {
  message("Processing sample: ", sam)
  derep_fwd <- derepFastq(fwd[[sam]])
  derep_rev <- derepFastq(rev[[sam]])

  dada_fwd[[sam]] <- dada(derep_fwd, err = err_fwd, multithread = TRUE)
  dada_rev[[sam]] <- dada(derep_rev, err = err_rev, multithread = TRUE)
  merged[[sam]] <- mergePairs(
    dada_fwd[[sam]],
    derep_fwd,
    dada_rev[[sam]],
    derep_rev,
    trimOverhang = TRUE
  )
}

saveRDS(merged, output)
saveRDS(dada_fwd, file.path(dirname(output), "dada_fwd.rds"))
saveRDS(dada_rev, file.path(dirname(output), "dada_rev.rds"))

options(warn = 0)
