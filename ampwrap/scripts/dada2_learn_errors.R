#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))




# Silenzia i warnings durante l'esecuzione
suppressWarnings({

    # Elenco dei file filtrati
    fwd <- list.files(input_dir, pattern = "_R1_filtered.fq.gz", full.names = TRUE)
    rev <- list.files(input_dir, pattern = "_R2_filtered.fq.gz", full.names = TRUE)

    # Impara gli errori
    err_fwd <- suppressMessages(err_fwd <- learnErrors(fwd, multithread = TRUE))
    err_rev <- suppressMessages(err_rev <- learnErrors(rev, multithread = TRUE))
    # Salva gli errori
    saveRDS(err_fwd, file.path(output_dir, "err_forward_reads.rds"))
    saveRDS(err_rev, file.path(output_dir, "err_reverse_reads.rds"))

    # Genera le immagini dei profili di errore
    png(file.path(output_dir, "err_forward_reads.png"))
    plotErrors(err_fwd, nominalQ = TRUE)
    garbage <-  dev.off()

    png(file.path(output_dir, "err_reverse_reads.png"))
    plotErrors(err_rev, nominalQ = TRUE)
    garbage <- dev.off()

})

options(warn=-0)
