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
- [Troubleshooting](#troubleshooting)

## Introduction
AmpWrap is a streamlined and efficient workflow for the analysis of 16S rRNA gene amplicons, supporting both short-read (Illumina) and long-read (Nanopore) sequencing technologies.

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
```sh
conda activate ampwrap

bash setup.sh
```


## General Usage
```sh
ampwrap --help
```
### AmpWrap for Short Reads (Illumina)
To process short-read 16S rRNA data from Illumina sequencing:
##  Workflow
1. Initial quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
2. Primer removal from sequencing reads with [Cutadapt](https://github.com/marcelm/cutadapt).
       The *--discard-untrimmed* option is applied
3. Post-cutadapt quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
4. Determine optimal trimming parameters for DADA2 with [Figaro](https://github.com/Zymo-Research/figaro)
5. Amplicon sequence variant inference with [DADA2](https://github.com/benjjneb/dada2)


Basic usage:
```sh
ampwrap short -i input_directory -a forward_primer -A reverse_primer -l amplicon_length
```
PS: Don't use it on multiple sequencing runs. If you want to analyze different runs, it's better to merge the DADA2 outputs after DADA2.

## Short reads Test Usage
You can use a small toy sequencing run to test ampwrap.
The following script will download fastq files and run ampwrap short
```sh
bash AmpWrap/test/test_short.sh
```

## Real 16S rRNA data V4V5 Test Usage
You can use a small true sequencing run to test ampwrap
```sh
bash AmpWrap/test/test_real_short_data.sh
```

If the test goes smoothly you are ready to analyze your data

### AmpWrap for Long Reads (Nanopore)
For long-read 16S rRNA data from Nanopore sequencing, use:
## Workflow
1. Initial quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
2. Adapters removal with [Porechop](https://github.com/rrwick/Porechop) or [Porechop_ABI](https://github.com/bonsai-team/Porechop_ABI). The use of **Porechop** is optional and depends on the `--trimming` parameter.
3. Primers removal with [Cutadapt](https://github.com/marcelm/cutadapt). The use of **Cutadapt** is optional and depends on the `--cutadapt-forward` and  `--cutadapt-reverse` parameters.
4. Filtering reads by length and quality with [NanoFilt](https://github.com/wdecoster/nanofilt)
5. Post-filtering quality control with [FastQC](https://github.com/s-andrews/FastQC) and QC report generation with [MultiQC](https://github.com/MultiQC/MultiQC)
6. Taxonomic classification and abundance estimation with [EMU](https://github.com/treangenlab/emu)

Basic usage:
```sh
ampwrap long -i input_directory -o output_directory
```
## Long reads Test Usage
You can use a small toy sequencing run to test ampwrap
```sh
bash AmpWrap/test/test_long.sh
```
Then you can use the [EMU](https://github.com/treangenlab/emu), scripts to combine the frequency tables:
```sh
emu combine-outputs <directory_path> <rank>
```



Further implementations can be requested by opening a issue





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

#### Potential Issue with Incorrect `-l` Settings  

If `-l` is not set properly (taking primer lengths into account), **Figaro** may select an incorrect pair of truncation parameters in **DADA2**, resulting in the following error:  

```bash
Warning message:
In filterAndTrim(forward_reads, filtered_forward_reads, reverse_reads,  :
No reads passed the filter. Please revisit your filtering parameters.
```
To avoid this issue, ensure that the chosen -l value aligns with the expected fragment lengths in your dataset.

 

