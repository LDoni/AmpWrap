args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_dir <- args[2]
figaro_params <- args[3]
user_params <- args[4]
options(warn=-1)
suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(jsonlite))

# Read Figaro Params
figaro <- fromJSON(figaro_params)

truncLen <- as.numeric(figaro$trimPosition[[1]])
maxEE <- as.numeric(figaro$maxExpectedError[[1]])

# Override user params
if (!is.na(user_params)) {
    user_params_list <- strsplit(user_params, ";")[[1]]
    for (p in user_params_list) {
        keyval <- strsplit(p, "=")[[1]]
        if (length(keyval) == 2) {
            key <- keyval[1]
            #val <- eval(parse(text = keyval[2]))
            val <- as.numeric(keyval[2])
            if (key == "truncLen") truncLen <- val
            if (key == "maxEE") maxEE <- val
        }
    }
}


# File list
fwd <- list.files(input_dir, pattern = "_trimmed_R1.fq.gz", full.names = TRUE)
rev <- list.files(input_dir, pattern = "_trimmed_R2.fq.gz", full.names = TRUE)

# Generate output
filt_fwd <- file.path(output_dir, basename(sub("_trimmed_R1.fq.gz", "_R1_filtered.fq.gz", fwd)))
filt_rev <- file.path(output_dir, basename(sub("_trimmed_R2.fq.gz", "_R2_filtered.fq.gz", rev)))

# Filter and trim
out <- filterAndTrim(fwd, filt_fwd, rev, filt_rev, truncLen = truncLen, maxEE = maxEE, multithread = TRUE)
sample_names <- sub("^([^_]+).*", "\\1", basename(fwd))
out_df <- data.frame(sample = sample_names, out)
write.table(out_df, file.path(output_dir, "filter_summary.tsv"), row.names = FALSE, sep = "\t", quote = FALSE)
options(warn=0)
