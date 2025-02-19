
args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]
figaro_params <- args[3]

library(dada2)

# Leggi i parametri di Figaro
figaro <- jsonlite::fromJSON(figaro_params)
truncLen <- as.numeric(figaro$trimPosition[[1]])
maxEE <- as.numeric(figaro$maxExpectedError[[1]])

# Elenco dei file
fwd <- list.files(input_dir, pattern = "_trimmed_R1.fq.gz", full.names = TRUE)
rev <- list.files(input_dir, pattern = "_trimmed_R2.fq.gz", full.names = TRUE)

# Genera output
filt_fwd <- file.path(output_dir, basename(sub("_trimmed_R1.fq.gz", "_R1_filtered.fq.gz", fwd)))
filt_rev <- file.path(output_dir, basename(sub("_trimmed_R2.fq.gz", "_R2_filtered.fq.gz", rev)))

# Filtra e ritaglia
filterAndTrim(fwd, filt_fwd, rev, filt_rev, truncLen = truncLen, maxEE = maxEE, multithread = TRUE)
