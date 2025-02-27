#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
err_fwd_file <- args[2]
err_rev_file <- args[3]
output <- args[4]

suppressPackageStartupMessages(library(dada2))

# Elenco dei file filtrati
fwd <- list.files(input_dir, pattern = "_R1_filtered.fq.gz", full.names = TRUE)
rev <- list.files(input_dir, pattern = "_R2_filtered.fq.gz", full.names = TRUE)

# Carica gli errori
err_fwd <- readRDS(err_fwd_file)
err_rev <- readRDS(err_rev_file)

# Dereplica
derep_fwd <- derepFastq(fwd)
derep_rev <- derepFastq(rev)

# Inferisci ASVs
dada_fwd <- dada(derep_fwd, err = err_fwd, multithread = TRUE)
dada_rev <- dada(derep_rev, err = err_rev, multithread = TRUE)

# Merging
merged <- mergePairs(dada_fwd, derep_fwd, dada_rev, derep_rev, trimOverhang = TRUE)

# Salva ASVs
saveRDS(merged, output)

saveRDS(dada_fwd, file.path(dirname(output), "dada_fwd.rds"))
saveRDS(dada_rev, file.path(dirname(output), "dada_rev.rds"))
