#!/usr/bin/env Rscript
options(warn=-1)
suppressPackageStartupMessages(library(dada2))

getN <- function(x) sum(getUniques(x))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 6) {
  stop("Usage: Rscript track_reads.R <filter_summary(s)> <dada_fwd(s)> <dada_rev(s)> <merged(s)> <seqtab_nochim_rds> <output_tsv>")
}


seqtab_nochim_rds <- args[length(args) - 1]
seqtab.nochim <- readRDS(seqtab_nochim_rds)
output_tsv <- args[length(args)]
n_files <- length(args) - 2
if (n_files %% 4 != 0) stop("Number of files (before seqtab_nochim)  has to be multiple of 4 for each different run")
n_runs <- n_files / 4
message("run found: ", n_runs)

getN <- function(x) sum(getUniques(x))

split_by_offset <- function(x, step) {
  lapply(seq_len(step), function(i) x[seq(i, length(x), by = step)])
}

name_variants <- function(n) {
  v <- character()
  v <- c(v, n)
  v <- c(v, sub("\\.fastq\\.gz$", "", n, ignore.case = TRUE))
  v <- c(v, sub("\\.fastq$", "", n, ignore.case = TRUE))
  v <- c(v, sub("\\.fq\\.gz$", "", n, ignore.case = TRUE))
  v <- c(v, sub("\\.fq$", "", n, ignore.case = TRUE))
  v <- c(v, sub("_filtered.*$", "", n))
  v <- c(v, sub("_R[12].*$", "", n))
  if (grepl("_", n)) v <- c(v, unlist(strsplit(n, "_"))[1])
  v <- c(v, basename(n))
  v <- unique(gsub("^\\s+|\\s+$", "", v))
  return(v)
}

find_input_for_sample <- function(sample_name, out_df, input_col) { # S summary reads.in
  if (sample_name %in% rownames(out_df)) return(out_df[sample_name, input_col, drop=TRUE])
  variants <- name_variants(sample_name)
  matches <- intersect(variants, rownames(out_df))
  if (length(matches) == 1) return(out_df[matches[1], input_col, drop=TRUE])
  if (length(matches) > 1) {
    warning(sprintf("Multiple matches for sample '%s': %s. Using first match '%s'.",
                    sample_name, paste(matches, collapse=", "), matches[1]))
    return(out_df[matches[1], input_col, drop=TRUE])
  }
  # no match
  warning(sprintf("No match found for sample '%s' in filter_summary. Returning NA.", sample_name))
  return(NA)
}

groups <- split_by_offset(args[1:n_files], step = n_runs)

analyze_run <- function(l){
  summary <- read.table(l[1],header=T,row.names=1)
  dada_fwd <- readRDS(l[2])
  dada_rev <- readRDS(l[3])
  merged <- readRDS(l[4])

  dadaF <- sapply(dada_fwd, getN)
  dadaR <- sapply(dada_rev, getN)
  merged <- sapply(merged, getN)
  sample_names <- names(dada_fwd)
  nonchim <- rowSums(seqtab.nochim)[sample_names]
  input_vec <- sapply(sample_names, function(s) find_input_for_sample(s, summary, "reads.in"), USE.NAMES = FALSE)

  return(cbind(summary,
                 dadaF = dadaF,
                 dadaR = dadaR,
                 merged = merged,
                 nonchim = nonchim,
                 total_retained =   round(nonchim / input_vec * 100, 1)))
}


track <- do.call(rbind, lapply(groups, analyze_run))
track["sample"] <- row.names(track)
track <- track[c("sample","reads.in","reads.out","dadaF","dadaR","merged","nonchim","total_retained")]
write.table(track[], output_tsv, row.names=FALSE, sep = "\t", quote = FALSE)
options(warn=0)
