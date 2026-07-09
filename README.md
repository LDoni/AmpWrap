<div align="center">
<pre>

   █████╗ ███╗   ███╗██████╗                        ██╗
  ██╔══██╗████╗ ████║██╔══██╗                       ╚██╗
  ███████║██╔████╔██║██████╔╝█████╗█████╗█████╗█████╗╚██╗
  ██╔══██║██║╚██╔╝██║██╔═══╝ ╚════╝╚════╝╚════╝╚════╝██╔╝
  ██║  ██║██║ ╚═╝ ██║██║                            ██╔╝
  ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝                            ╚═╝
    ██╗                 ██╗    ██╗██████╗  █████╗ ██████╗
   ██╔╝                 ██║    ██║██╔══██╗██╔══██╗██╔══██╗
  ██╔╝█████╗█████╗█████╗██║ █╗ ██║██████╔╝███████║██████╔╝
  ╚██╗╚════╝╚════╝╚════╝██║███╗██║██╔══██╗██╔══██║██╔═══╝
   ╚██╗                 ╚███╔███╔╝██║  ██║██║  ██║██║
    ╚═╝                  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝

</pre>
</div>



> AmpWrap A powerful workflow for the analysis of short and long 16S rRNA gene amplicons.

![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54) ![R](https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white) ![Bash](https://img.shields.io/badge/bash-%234EAA25.svg?style=for-the-badge&logo=gnu-bash&logoColor=white) ![Snakemake](https://img.shields.io/badge/Snakemake-svg?style=for-the-badge&logo=c&logoColor=white) 

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.17513793.svg)](https://doi.org/10.5281/zenodo.17513793)



## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
  - [Install Miniconda](#install-miniconda)
  - [Install Mamba](#install-mamba)
  - [Install AmpWrap](#install-ampwrap)
- [Usage](#general-usage)
  - [AmpWrap for Short Reads (Illumina)](#ampwrap-for-short-reads-illumina)
  - [AmpWrap for Long Reads (Nanopore)](#ampwrap-for-long-reads-nanopore)
  - [Running on HPC systems (SLURM/SGE)](#running-on-hpc-systems-slurmsge)
  - [Resumability and checkpointing](#resumability-and-checkpointing)

- [Troubleshooting](#troubleshooting)

## Introduction
AmpWrap is a streamlined and efficient workflow for the analysis of 16S rRNA gene amplicons, supporting both short-read (Illumina) and long-read (Nanopore) sequencing technologies.

It was tested on Linux Mint 20, Ubuntu 24.04.1 LTS, WSL2 with Ubuntu 24.04.2 LTS

## Installation 
AmpWrap can be easily installed using GitHub + Conda or Mamba.

### Install Miniconda
To use Conda or Mamba, you first need to install Miniconda:

```sh
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```

Run the installation script:
and remember to Init conda (final yes!)
```sh
bash ~/Miniconda3-latest-Linux-x86_64.sh
```

```
source ~/.bash_profile || source ~/.bashrc
```

After installation, remove the installer to free up space:
```sh
rm -rf ~/Miniconda3-latest-Linux-x86_64.sh
```

### Install Mamba
Mamba is a faster alternative to Conda for package management. Install it with:
```sh
conda install -n base -c conda-forge mamba
```

### Install AmpWrap
Install AmpWrap:

```sh
git clone https://github.com/LDoni/AmpWrap.git

cd AmpWrap/ampwrap/
```
Build up the environment

```sh
mamba env create -f ampwrap.yml
```
or
```sh
conda env create -f ampwrap.yml
```

Install AmpWrap
```sh
conda activate ampwrap
bash setup.sh
```


The package version is read from `ampwrap/VERSION`, which is also the version shown in the launcher help and final reports.

or 
## Install with docker
```sh
docker pull ghcr.io/ldoni/ampwrap:v1.1.1
docker run --rm ghcr.io/ldoni/ampwrap:v1.1.1 --help
```


## General Usage
```sh
ampwrap --help
```





## Supported input formats

The pipeline accepts two main naming conventions for paired-end FASTQ files.

### 1. Illumina Standard Format
The standard Illumina output naming convention:
```
<group>_<sample>_S##_L###_R[12]_001.(fastq|fq)[.gz]
```

**Example:**
```
ProjectA_Sample1_S1_L001_R1_001.fastq.gz
ProjectA_Sample1_S1_L001_R2_001.fastq.gz
```

### 2. Custom Simple Format
A simpler, more generic naming convention:
```
<sample>_[Rr][12].(fastq|fq)[.gz]
```

**Examples:**
```
SampleA_R1.fastq.gz
SampleA_R2.fastq.gz

S1_r1.fq.gz
S1_r2.fq.gz
```

If input files do not follow one of these paired-end conventions, AmpWrap reports the expected formats explicitly and shows which parser failed.

AmpWrap short also aborts early if it detects likely mate-pair typos where `R1` and `R2` only differ by small basename edits, for example:

```text
sample_A_R1.fastq.gz
sample-A_R2.fastq.gz
```

This avoids silent pairing mistakes caused by `_` vs `-` or similar accidental renaming differences.

## Database cache

AmpWrap now uses a central database cache by default instead of copying databases into each clone or conda environment.

- Short-read taxonomy databases default to `~/.ampwrap/db`
- Long-read EMU databases default to `~/.ampwrap/db/emu`
- You can override the location with `--db-dir`
- You can also set `AMPWRAP_DB_DIR` globally

Downloaded databases are tracked in a small manifest file:

```text
~/.ampwrap/db/manifest.tsv
```

The manifest stores:

- category
- name
- filename
- md5
- source_url
- local_path
- last_checked

You can inspect the cache with:

```sh
ampwrap db list
ampwrap db list --category dada2
```

## AmpWrap for Short Reads (Illumina)
To process short-read 16S rRNA gene data from Illumina sequencing:
##  Workflow
1. Initial quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
2. Primer removal from sequencing reads with [Cutadapt](https://github.com/marcelm/cutadapt).
       The *--discard-untrimmed* option is applied
3. Post-cutadapt quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
4. Determine optimal trimming parameters for DADA2 with [FIGARO](https://github.com/Zymo-Research/figaro)
5. Amplicon sequence variant inference with [DADA2](https://github.com/benjjneb/dada2)


Basic usage:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l amplicon_length
```

If `-o/--output_directory` is omitted, AmpWrap creates a timestamped output directory, for example:

```text
ampwrap_short_20260331_114500
```

Optional 16S species-level annotation with exact matching:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l amplicon_length --species
```
`--species` adds a DADA2 `addSpecies(...)` step after genus-level assignment. It is currently supported only for `dada2_silva_genus138` and `dada2_RDP_genus19`, and it uses exact matching only.

If you want to skip FIGARO and provide DADA2 trimming/filtering parameters directly:
```sh
ampwrap short \
  -i input_directory \
  -a forward_primer \
  -A reverse_primer \
  --dada2_params 'truncLen=c(240,200);maxEE=c(2,2)'
```

When `--dada2_params` is used, both `truncLen` and `maxEE` are required and `-l` is no longer mandatory.

Multiple Run usage:
```sh
ampwrap short -i input_directory1 input_directory2 -a forward_primer -A reverse_primer -l amplicon_length --trim-primers-dada2
```
In multiple-run mode, we recommend `--trim-primers-dada2` so primer removal is consistent across runs before ASV comparison and merging.
ASVs are merged by final sequence, so inconsistent primer removal is more problematic than differences in DADA2 truncation when the amplicon still merges correctly.

In multiple-run mode, run folders are named after the input directory basenames instead of generic `run_1`, `run_2`, etc.

### Additional useful options

Species-level assignment for supported 16S DADA2 databases:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 -d dada2_silva_genus138 --species
```

Manual DADA2 parameters:
```sh
ampwrap short \
  -i input_directory \
  -a FORWARD \
  -A REVERSE \
  --dada2_params 'truncLen=c(240,200);maxEE=c(2,2)'
```

When `--dada2_params` is used, both `truncLen` and `maxEE` must be present and `-l` is not required because FIGARO is bypassed.

Automatic/shared error model selection for binned qualities:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --loess_model auto
```

Force a specific error model:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --loess_model 1
```

#### `--loess_model` notes

AmpWrap keeps the standard DADA2 error-learning model as `vanilla` and adds a small set of alternative loess fits (`1` to `4`) that can behave better on quality-binned data, especially NovaSeq-style datasets.

- `vanilla`: default DADA2 behaviour
- `1` to `4`: alternative smoothed fits with different weighting/regularization choices
- `auto`: evaluates the available models on held-out data and selects the best one, then enforces the same selected model for forward and reverse reads

These models are still DADA2-based error models. They do not replace DADA2 denoising; they only change the smooth fit used during `learnErrors()`.

Background and citations:
- Callahan BJ et al. 2016. DADA2: High-resolution sample inference from Illumina amplicon data. *Nature Methods* 13:581-583.
- DADA2 tutorial and error-learning documentation: <https://benjjneb.github.io/dada2/tutorial.html>


Cap very deep libraries before QC/trimming:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --max-reads-per-sample 200000
```

This is useful for oversized NovaSeq metabarcoding libraries when you want to keep a reproducible random subset of reads and reduce runtime and memory usage.

Use `--max-reads-per-sample` only as an explicit fixed cap when you want to downsample very deep libraries before QC and denoising.

Very deep NovaSeq libraries:
```sh
ampwrap short \
  -i input_directory \
  -a FORWARD \
  -A REVERSE \
  -l 372 \
  --max-reads-per-sample 200000
```

This is useful when the biological target typically needs around `100k-200k` reads per sample but sequencing produced much deeper libraries.

Convenience profile for very large runs:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --bigdata
```

`--bigdata` currently enables safer defaults for deep datasets and uses the streaming-style sample inference workflow.

Without `--bigdata`, AmpWrap keeps the standard DADA2-style inference path.

Optional ASV length filter after merging/chimera removal:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --asv-length auto
```

This keeps ASVs around the dominant observed length and warns if the dominant length differs substantially from the expected amplicon length.

Explicit ASV length range:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --asv-length 360:385
```

This is useful when you want to retain only ASVs within a user-defined sequence-length interval after chimera removal.

Optional organelle-filtered phyloseq outputs:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --remove-organelle-phyloseq
```

This keeps the standard outputs unchanged and additionally writes:
- `phyloseq_object_no_organelle.rds`
- `ASVs_counts_no_organelle.tsv`
- `ASVs_taxonomy_no_organelle.tsv`
- `ASVs_no_organelle.biom`

Accepted short-read input names:
```text
Custom:   sample_R1.fastq.gz / sample_R2.fastq.gz
Illumina: sample_S1_L001_R1_001.fastq.gz / sample_S1_L001_R2_001.fastq.gz
```

Supported extensions are `.fq`, `.fq.gz`, `.fastq`, and `.fastq.gz`.

Resource profiles:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l 372 --resource-profile balanced -c 8
```

Available profiles are `safe`, `balanced`, and `aggressive`.
They increase CPU usage on preprocessing and QC steps while keeping DADA2-related steps more conservative.

Store databases in a stable shared directory:
```sh
ampwrap short \
  -i input_directory \
  -a forward_primer \
  -A reverse_primer \
  -l 372 \
  --db-dir /path/to/shared_ampwrap_db
```

If `AMPWRAP_DB_DIR` is set, AmpWrap short uses it automatically.

Readable command-line help:
```sh
ampwrap short --help
```

The short-read parser is grouped by topic:
- required arguments
- general options
- denoising and trimming
- execution

This makes it easier to distinguish mandatory inputs from optional DADA2, downsampling, and runtime controls.


## Short reads Test Usage
You can use a small toy sequencing run to test AmpWrap.
The following script will download fastq files and run AmpWrap short
```sh
bash ~/AmpWrap/test/test_short.sh
```

## Real 16S rRNA gene data V4V5 Test Usage
You can use a small true sequencing run to test AmpWrap
```sh
bash ~/AmpWrap/test/test_real_short_data.sh
```

## Real 18S rRNA gene data V4 Test Usage
You can use a small true sequencing run to test AmpWrap
```sh
bash ~/AmpWrap/test/test_real_short_data18S.sh
```
 

If the test goes smoothly you are ready to analyze your data

## Available databases for AmpWrap short

| Database Name        | Source   | Version / Date | File Name                                | MD5                              | Download Link                                                                                            |
| -------------------- | -------- | -------------- | ---------------------------------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| SILVA SSU r138.2     | DECIPHER | 2024           | SILVA_SSU_r138.2_v2.RData                | ed0b7e62542cd5615fb77ef15bcb9de0 | [Download](https://drive.usercontent.google.com/download?export=download&id=11YYCiB-gJqAP7-wIu35smorelLE-7IgJ&confirm=t) |
| GTDB r226            | DECIPHER | April 2025     | GTDB_r226_classifier.RData               | 2aca8a1cfc4c8357a61eb51413f4e476 | [Download](https://drive.usercontent.google.com/download?export=download&id=1wMS2jskFeI9RGXn3fBO_yyvciiB8PMu0&confirm=t) |
| RDP v18              | DECIPHER | July 2020      | RDP_TrainingSet_v18.RData                | af228a61cf5c382e847770c53a8d531b | [Download](https://drive.usercontent.google.com/download?export=download&id=1AsgpYQtheSuZbFkOD9HFZZm81A-IM5UO&confirm=t) |
| RDP v19              | DADA2    | 2023-08-23     | rdp_19_toGenus_trainset.fa.gz            | 390b8a359c45648adf538e72a1ee7e28 | [Download](https://zenodo.org/records/14168771/files/rdp_19_toGenus_trainset.fa.gz?download=1)                       |
| SILVA v138.2         | DADA2    | 2025           | silva_nr99_v138.2_toGenus_trainset.fa.gz | 1764e2a36b4500ccb1c7d5261948a414 | [Download](https://zenodo.org/records/16777407/files/silva_nr99_v138.2_toGenus_trainset.fa.gz?download=1)            |
| RefSeq+RDP v16       | DADA2    | 2020-06-11     | RefSeq_16S_6-11-20_RDPv16_Genus.fa.gz    | 53aac0449c41db387d78a3c17b06ad07 | [Download](https://zenodo.org/records/4735821/files/RefSeq_16S_6-11-20_RDPv16_Genus.fa.gz?download=1)                |
| GTDB r202            | DADA2    | 2020-04-28     | GTDB_bac120_arc122_ssu_r202_Genus.fa.gz  | 40c1ee877ad2c5dca81e1cdf9a52ac3a | [Download](https://zenodo.org/records/4735821/files/GTDB_bac120_arc122_ssu_r202_Genus.fa.gz?download=1)              |
| Greengenes2 2024.09  | DADA2    | 2024-09        | gg2_2024_09_toGenus_trainset.fa.gz       | 82a2571c9ff5009cbd2f3fded79069ed | [Download](https://zenodo.org/records/14169078/files/gg2_2024_09_toGenus_trainset.fa.gz?download=1)                  |
| PR2 version 5.1.1    | DADA2    | 2025-10        | pr2_version_5.1.1_SSU_dada2.fasta.gz     | cab726022035241ce1f05a24dd3ef707 | [Download](https://github.com/pr2database/pr2database/releases/download/v5.1.1/pr2_version_5.1.1_SSU_dada2.fasta.gz) |
| DADA2 18S Silva V132 | DADA2    | 2024-01        | DADA2_silva_v132_18S.fa                  | 3bbab8029675474805d1a5d24cf23bb9 | [Download](https://zenodo.org/records/10444891/files/DADA2_silva_v132_18S.fa?download=1)                       |


## AmpWrap for Long Reads (Nanopore)
If `-o/--output-directory` is omitted, AmpWrap creates a timestamped output directory, for example:

```text
ampwrap_long_20260331_114500
```

For long-read 16S rRNA gene data from Nanopore sequencing, use:
## Workflow
1. Initial quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
2. Adapters removal with [Porechop](https://github.com/rrwick/Porechop) or [Porechop_ABI](https://github.com/bonsai-team/Porechop_ABI). The use of **Porechop** is optional and depends on the `--trimming` parameter.
3. Primers removal with [Cutadapt](https://github.com/marcelm/cutadapt). The use of **Cutadapt** is optional and depends on the `--cutadapt-forward` and  `--cutadapt-reverse` parameters.
4. Filtering reads by length and quality with [NanoFilt](https://github.com/wdecoster/nanofilt)
5. Post-filtering quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
6. Detect chimeras and filter them out (optional) with [yacrd](https://github.com/natir/yacrd)
7. Taxonomic classification and abundance estimation with [EMU](https://github.com/treangenlab/emu)

Basic usage:
```sh
ampwrap long -i input_directory -o output_directory
```

Database notes for `ampwrap long`:
- the default EMU cache is `~/.ampwrap/db/emu`
- you can override it with `--db-dir`
- `ampwrap long --help` prints the active default path
- PR2 prebuilt EMU databases are normalized internally to the canonical EMU layout required by `emu abundance`

Long-read sample naming:
- input sample names are derived from the FASTQ basename after stripping `.fastq`, `.fq`, `.fastq.gz`, or `.fq.gz`
- intermediate filenames may still contain `-nanofilt` or `-scrubbed`
- final sample names in the report and in `emu_phyloseq.rds` are written without those suffixes
## Long reads Test Usage
You can use a small toy sequencing run to test AmpWrap
```sh
bash ~/AmpWrap/test/test_long.sh
```
Then you can use the [EMU](https://github.com/treangenlab/emu), scripts to combine the frequency tables:
```sh
emu combine-outputs <directory_path> <rank>
```

For negative control samples we suggest to use the --keep-counts flag to to retain per-taxon counts, and then use tools such as [decontam](https://github.com/benjjneb/decontam), not included in ampwrap.






Further implementations can be requested by opening a issue


### Running on HPC systems (SLURM/SGE)

AmpWrap is Snakemake-based and can run seamlessly on HPC/queue systems.  
We provide example cluster profiles for **SLURM** and **SGE** in the [`profiles/`](profiles) directory.

To launch AmpWrap on **SLURM**:
```sh
snakemake --profile profiles/slurm
```

on **SGE**:
```sh
snakemake --profile profiles/sge
```

### Resumability and checkpointing

Snakemake natively supports resumability:

- If a run is interrupted, simply re-run the same command and only incomplete or outdated steps will be executed.  
- The provided HPC profiles enable:
  - `--rerun-incomplete`: automatically re-run unfinished jobs  
  - `--restart-times N`: retry failed jobs up to *N* times  
  - `--keep-going`: continue executing independent jobs even if one fails  

These options ensure robust and reproducible execution, especially for large cohorts or long HPC runs.


## Troubleshooting
If you encounter issues during installation or execution, check the following:
- Ensure that Conda/Mamba is properly installed and activated.
```sh
conda --help
```
- Verify that AmpWrap is installed in the correct Conda environment.

```sh
ampwrap short --help
```

### AttributeError: module 'pulp' has no attribute 'list_solvers'
```sh
conda install --force-reinstall conda-forge::pulp
```

### V3-V4 Analysis

Using the primers suggested in the Illumina protocol:

- **Forward:** `CCTACGGGNGGCWGCAG`
- **Reverse:** `GACTACHVGGGTATCTAATCC`

you might encounter an issue when setting the `-l` parameter due to variation in the lengths of 16S segments. While this variation is not large, it does exist. In particular, there are two predominant **V3-V4** fragment lengths in nature:  

- **~460 nts**
- **~440 nts**  

#### Choosing the Correct `-l` Parameter  

To account for this variation, consider checking which option is better for your analysis:  

- `-l 444` → `464 - 38` (primers)  
- `-l 426` → `444 - 38` (primers)  
Therefore, for the calculation of the FIGARO parameters, for amplicons with some expected biological variation in length, it is best to use the longest expected size. 
#### Potential Issue with Incorrect `-l` Settings  

If `-l` is not set properly (taking primer lengths into account), **FIGARO** may select an incorrect pair of truncation parameters in **DADA2**, resulting in the following error:  

```bash
Warning message:
In filterAndTrim(forward_reads, filtered_forward_reads, reverse_reads,  :
No reads passed the filter. Please revisit your filtering parameters.
```
To avoid this issue, ensure that the chosen -l value aligns with the expected fragment lengths in your dataset.
For amplicons with some expected biological variation in length, use the longest expected size

### Input naming errors

AmpWrap short only accepts paired-end FASTQ files that match one of the supported naming conventions.

Accepted examples:
```text
sample_R1.fastq.gz
sample_R2.fastq.gz

sample_S1_L001_R1_001.fastq.gz
sample_S1_L001_R2_001.fastq.gz
```

If a directory does not contain valid pairs, AmpWrap now reports:
- that no recognizable `_R1` / `_R2` FASTQ files were found, or
- that the parser could not match the supported formats, or
- which sample is missing an `R1` or `R2` mate
- when `R1` and `R2` look like the same sample except for small naming differences, that AmpWrap detected a probable pair typo
