
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
```sh
conda activate ampwrap

bash setup.sh
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






### AmpWrap for Short Reads (Illumina)
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
PS: Don't use it on multiple sequencing runs. If you want to analyze different runs, it's better to merge the DADA2 outputs after DADA2.

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

If the test goes smoothly you are ready to analyze your data

## Available databases for AmpWrap short

| Database Name           | Source    | Version / Date | File Name                                | MD5                               | Download Link | Citation |
|-------------------------|-----------|----------------|------------------------------------------|------------------------------------|---------------|---------------|
| SILVA SSU r138.2        | DECIPHER  | 2024           | SILVA_SSU_r138_2_2024.RData              | `4e272e39c2d71f5d3e7a31b00dbb1df4` | [Download](https://www2.decipher.codes/data/Downloads/TrainingSets/SILVA_SSU_r138_2_2024.RData) | Quast C. et al.,  2013 |
| GTDB r226               | DECIPHER  | April 2025     | GTDB_r226-mod_April2025.RData            | `2aca8a1cfc4c8357a61eb51413f4e476` | [Download](https://www2.decipher.codes/data/Downloads/TrainingSets/GTDB_r226-mod_April2025.RData) | Parks D. et al., 2022|
| RDP v18                 | DECIPHER  | July 2020      | RDP_v18-mod_July2020.RData               | `e0e8ed5bc34b28ab416df2d7fc1568ec` | [Download](https://www2.decipher.codes/data/Downloads/TrainingSets/RDP_v18-mod_July2020.RData) | Cole JR, et al., 2014 |
| RDP v19                 | DADA2     | 2023-08-23     | rdp_19_toGenus_trainset.fa.gz            | `390b8a359c45648adf538e72a1ee7e28` | [Download](https://zenodo.org/records/14168771/files/rdp_19_toGenus_trainset.fa.gz?download=1) | Callahan, B. 2024  |
| SILVA v138.2            | DADA2     | 2025           | silva_nr99_v138.2_toGenus_trainset.fa.gz | `1764e2a36b4500ccb1c7d5261948a414` | [Download](https://zenodo.org/records/16777407/files/silva_nr99_v138.2_toGenus_trainset.fa.gz?download=1) | Quast C. et al.,  2013 |
| RefSeq+RDP v16          | DADA2     | 2020-06-11     | RefSeq_16S_6-11-20_RDPv16_Genus.fa.gz    | `53aac0449c41db387d78a3c17b06ad07` | [Download](https://zenodo.org/records/4735821/files/RefSeq_16S_6-11-20_RDPv16_Genus.fa.gz?download=1) | Ali A. 2021 |
| GTDB r202               | DADA2     | 2020-04-28     | GTDB_bac120_arc122_ssu_r202_Genus.fa.gz  | `40c1ee877ad2c5dca81e1cdf9a52ac3a` | [Download](https://zenodo.org/records/4735821/files/GTDB_bac120_arc122_ssu_r202_Genus.fa.gz?download=1) | Ali A. 2021 |
| Greengenes2 2024.09     | DADA2     | 2024-09        | gg2_2024_09_toGenus_trainset.fa.gz       | `82a2571c9ff5009cbd2f3fded79069ed` | [Download](https://zenodo.org/records/14169078/files/gg2_2024_09_toGenus_trainset.fa.gz?download=1) | Callahan, B. 2024 |

## Multi Run 
To use ampwrap short on multi run batch, we suggest to run reparately (in different filder) the workflow.

It also assumes that you have trimmed the runs in the same fashion, which is what I would recommend if you are combining runs. If you didn't, but the difference is just a couple extra nts at the end of one run, you can just trim them off (eg. rownames(st2) <- substr(rownames(st2, 1, 232))). For merged reads this is less of an issue generally, as long as you used the same trimLeft parameters in each run, as differences in truncLen shouldn't affect the length of the merged sequence.

https://github.com/benjjneb/dada2/issues/95






### AmpWrap for Long Reads (Nanopore)
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
 

