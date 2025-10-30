#!/usr/bin/env Rscript --vanilla

suppressPackageStartupMessages(library(dada2))
options(warn = -1)
options(warn=0)

args <- commandArgs(trailingOnly = TRUE)
input_files <- head(args, -1)
output_file <- tail(args, 1)

missing_files <- input_files[!file.exists(input_files)]
if (length(missing_files) > 0) {
  stop("Missing ASV table(s):\n", paste(missing_files, collapse = "\n"))
}

print(input_files)
tables <- lapply(input_files, readRDS)
st.all <- mergeSequenceTables(tables=tables)
saveRDS(st.all, output_file)

