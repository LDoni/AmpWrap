args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]
figaro_params <- args[3]
user_params <- args[4]

options(warn=-1)
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(jsonlite))

truncLen <- NULL
maxEE <- NULL

# 1) Read Figaro params only if a real file path is given
if (!is.null(figaro_params) && figaro_params != "" && figaro_params != "NONE" && file.exists(figaro_params)) {
  figaro <- fromJSON(figaro_params)
  truncLen <- as.numeric(unlist(figaro$trimPosition[[1]]))
  maxEE <- as.numeric(unlist(figaro$maxExpectedError[[1]]))
}

# 2) Override from user params (if provided)
if (!is.null(user_params) && user_params != "" && user_params != "None" && user_params != "NA") {
  user_params_list <- strsplit(user_params, ";", fixed = TRUE)[[1]]
  for (p in user_params_list) {
    keyval <- strsplit(p, "=", fixed = TRUE)[[1]]
    if (length(keyval) == 2) {
      key <- trimws(keyval[1])
      val <- eval(parse(text = keyval[2]))
      if (key == "truncLen") truncLen <- val
      if (key == "maxEE") maxEE <- val
    }
  }
}

# 3) Stop if still missing
if (is.null(truncLen) || is.null(maxEE)) {
  stop("No valid truncLen/maxEE found. Provide Figaro JSON or pass --dada2_params like 'truncLen=c(240,200);maxEE=c(2,2)'.")
}

truncLen <- as.vector(truncLen)
maxEE <- as.vector(maxEE)

# File list
fwd <- list.files(input_dir, pattern = "_trimmed_R1.fq.gz", full.names = TRUE)
rev <- list.files(input_dir, pattern = "_trimmed_R2.fq.gz", full.names = TRUE)

# Output paths
filt_fwd <- file.path(output_dir, basename(sub("_trimmed_R1.fq.gz", "_R1_filtered.fq.gz", fwd)))
filt_rev <- file.path(output_dir, basename(sub("_trimmed_R2.fq.gz", "_R2_filtered.fq.gz", rev)))

# Run DADA2 filtering
out <- filterAndTrim(fwd, filt_fwd, rev, filt_rev, truncLen = truncLen, maxEE = maxEE, multithread = TRUE)

# Save summary
sample_names <- sub("^([^_]+).*", "\\1", basename(fwd))
out_df <- data.frame(sample = sample_names, out)
write.table(out_df, file.path(output_dir, "filter_summary.tsv"), row.names = FALSE, sep = "\t", quote = FALSE)

options(warn=0)
