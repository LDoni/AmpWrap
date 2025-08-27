args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]
figaro_params <- args[3]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(jsonlite))

# Leggi i parametri di Figaro
figaro <- fromJSON(figaro_params)

truncLen <- as.numeric(figaro$trimPosition[[1]])
maxEE <- as.numeric(figaro$maxExpectedError[[1]])

# Elenco dei file
fwd <- list.files(input_dir, pattern = "_trimmed_R1.fq.gz", full.names = TRUE)
rev <- list.files(input_dir, pattern = "_trimmed_R2.fq.gz", full.names = TRUE)

# Genera output
filt_fwd <- file.path(output_dir, basename(sub("_trimmed_R1.fq.gz", "_R1_filtered.fq.gz", fwd)))
filt_rev <- file.path(output_dir, basename(sub("_trimmed_R2.fq.gz", "_R2_filtered.fq.gz", rev)))

# Filtra e ritaglia
out <- filterAndTrim(fwd, filt_fwd, rev, filt_rev, truncLen = truncLen, maxEE = maxEE, multithread = TRUE)
sample_names <- sub("^([^_]+).*", "\\1", basename(fwd))
out_df <- data.frame(sample = sample_names, out)
write.table(out_df, file.path(output_dir, "filter_summary.tsv"), row.names = FALSE, sep = "\t", quote = FALSE)
options(warn=0)
