#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))




suppressWarnings({

    fwd <- list.files(input_dir, pattern = "_R1_filtered.fq.gz", full.names = TRUE)
    rev <- list.files(input_dir, pattern = "_R2_filtered.fq.gz", full.names = TRUE)

    err_fwd <- suppressMessages(err_fwd <- learnErrors(fwd, multithread = TRUE))
    err_rev <- suppressMessages(err_rev <- learnErrors(rev, multithread = TRUE))


    saveRDS(err_fwd, file.path(output_dir, "err_forward_reads.rds"))
    saveRDS(err_rev, file.path(output_dir, "err_reverse_reads.rds"))


})

options(warn=-0)




    pdf(file.path(output_dir, "err_forward_reads.pdf"))
    plotErrors(err_fwd, nominalQ = TRUE)
    dev.off()

    pdf(file.path(output_dir, "err_reverse_reads.pdf"))
    plotErrors(err_rev, nominalQ = TRUE)
    dev.off()





