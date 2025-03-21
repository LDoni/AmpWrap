# AmpWrap
> A powerful workflow for the analysis of short and long 16S rRNA gene amplicons.

![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54) ![R](https://img.shields.io/badge/r-%23276DC3.svg?style=for-the-badge&logo=r&logoColor=white) ![Bash](https://img.shields.io/badge/bash-%234EAA25.svg?style=for-the-badge&logo=gnu-bash&logoColor=white) ![Snakemake](https://img.shields.io/badge/Snakemake-svg?style=for-the-badge&logo=c&logoColor=white) 

## Table of Contents
- [Introduction](#introduction)
- [Installation with Conda](#installation-with-conda)
  - [Install Miniconda](#install-miniconda)
  - [Install Mamba](#install-mamba)
  - [Install AmpWrap](#install-ampwrap)
- [Usage](#usage)
  - [AmpWrap for Short Reads (Illumina)](#ampwrap-for-short-reads-illumina)
  - [AmpWrap for Long Reads (Nanopore)](#ampwrap-for-long-reads-nanopore)  
- [Workflow](#workflow)
  - [Illumina](#illumina-workflow)
  - [Nanopore](#nanopore-workflow)
- [Troubleshooting](#troubleshooting)

## Introduction
AmpWrap is a streamlined and efficient workflow for the analysis of 16S rRNA amplicons, supporting both short-read (Illumina) and long-read (Nanopore) sequencing technologies.

## Installation with Conda
AmpWrap can be easily installed using Conda or Mamba.

### Install Miniconda
To use Conda or Mamba, you first need to install Miniconda:

```sh
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
```

Run the installation script:
```sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
source ~/.bash_profile || source ~/.bashrc
```

After installation, remove the installer to free up space:
```sh
rm -rf ~/miniconda3/miniconda.sh
```

### Install Mamba
Mamba is a faster alternative to Conda for package management. Install it with:

```sh
conda install -n base -c conda-forge mamba
```

### Install AmpWrap
You can install AmpWrap using either Conda or Mamba:

```sh
conda install -c bioconda ampwrap
```

or using Mamba:

```sh
mamba install -c bioconda ampwrap
```

## Usage

### AmpWrap for Short Reads (Illumina)
To process short-read 16S rRNA data from Illumina sequencing, use:

Basic usage:
```sh
ampwrap illumina -i input_directory -a forward_primer -A reverse_primer -l amplicon_length
```
PS: Don't use it on multiple sequencing runs. If you want to analyze different runs, it's better to merge the DADA2 outputs after DADA2.

### AmpWrap for Long Reads (Nanopore)
For long-read 16S rRNA data from Nanopore sequencing, use:

```sh
ampwrap nanopore -i input_directory -o output_directory
```

Further implementations can be requested by opening a issue

## Illumina Workflow
1. Initial quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
2. Primer removal from sequencing reads with [Cutadapt](https://github.com/marcelm/cutadapt).
       The *--discard-untrimmed* option is applied
3. Post-cutadapt quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
4. Determine optimal trimming parameters for DADA2 with [Figaro](https://github.com/Zymo-Research/figaro)
5. Amplicon sequence variant inference with [DADA2](https://github.com/benjjneb/dada2)

## Nanopore Workflow
1. Initial quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
2. Primer removal with [Porechop](https://github.com/rrwick/Porechop). The use of **Porechop** is optional and depends on the `trimming_method` parameter in the config file.
3. Filtering reads by length with [NanoFilt](https://github.com/wdecoster/nanofilt)
4. Post-filtering quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
5. Taxonomic classification and abundance estimation with [EMU](https://github.com/treangenlab/emu)

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

#### Potential Issue with Incorrect `-l` Settings  

If `-l` is not set properly (taking primer lengths into account), **Figaro** may select an incorrect pair of truncation parameters in **DADA2**, resulting in the following error:  

```bash
Warning message:
In filterAndTrim(forward_reads, filtered_forward_reads, reverse_reads,  :
No reads passed the filter. Please revisit your filtering parameters.
```
To avoid this issue, ensure that the chosen -l value aligns with the expected fragment lengths in your dataset.

 

