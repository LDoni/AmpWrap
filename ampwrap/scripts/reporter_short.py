#!/usr/bin/env python3
import pandas as pd
import json
import datetime
import os
import glob
import sys

if getattr(snakemake, "log", None):
    log_path = str(snakemake.log[0])
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
    log_handle = open(log_path, "w")
    sys.stdout = log_handle
    sys.stderr = log_handle

output_dir = snakemake.params.get("output_dir")
if not output_dir:
    output_dir = os.path.dirname(os.path.dirname(snakemake.output.report))
run_names = [str(run) for run in snakemake.params.get("runs", [])]
run_dirs = [os.path.join(output_dir, run_name) for run_name in run_names if os.path.isdir(os.path.join(output_dir, run_name))]
if not run_dirs:
    raise FileNotFoundError(f"No run directories found in {output_dir}")

run_reports = []
dada2_params = snakemake.params["dada2_params"]
loess_model = str(snakemake.params.get("loess_model", "NA")).strip().upper()


def parse_percent(value):
    return float(str(value).strip().rstrip("%"))


def format_count_percent(count, total):
    if total <= 0:
        return str(int(count))
    pct = (float(count) / float(total)) * 100
    return f"{int(count)} ({pct:.1f}%)"


def build_denoising_table(cutadapt_df, dada2_df):
    df = pd.merge(cutadapt_df, dada2_df, on="sample", how="inner")
    if df.empty:
        raise ValueError("No overlapping sample names between cutadapt and DADA2 tracking tables")
    df["reads_retained"] = pd.to_numeric(df["reads_retained"])
    df["raw_reads"] = df["reads_retained"].astype(int)

    report_df = pd.DataFrame({
        "sample": df["sample"],
        "raw_reads": df["raw_reads"].astype(int).astype(str),
        "cutadapt": df.apply(lambda row: format_count_percent(row["reads.in"], row["raw_reads"]), axis=1),
        "filtered": df.apply(lambda row: format_count_percent(row["reads.out"], row["raw_reads"]), axis=1),
        "dadaF": df.apply(lambda row: format_count_percent(row["dadaF"], row["raw_reads"]), axis=1),
        "dadaR": df.apply(lambda row: format_count_percent(row["dadaR"], row["raw_reads"]), axis=1),
        "merged": df.apply(lambda row: format_count_percent(row["merged"], row["raw_reads"]), axis=1),
        "nonchim": df.apply(lambda row: format_count_percent(row["nonchim"], row["raw_reads"]), axis=1),
    })
    return report_df.set_index("sample")


def format_error_models(run_dir):
    metadata_files = glob.glob(os.path.join(run_dir, "intermediate/dada2_error_learning/model_selection.tsv"))
    if not metadata_files:
        return ""

    metadata = pd.read_table(metadata_files[0])
    lines = []
    for _, row in metadata.iterrows():
        direction = str(row["direction"]).strip()
        requested = str(row["requested_model"]).strip()
        selected = str(row["selected_model"]).strip()
        reason = str(row["selection_reason"]).strip()
        if requested == selected:
            lines.append(f"{direction}_error_model: {selected} ({reason})")
        else:
            lines.append(f"{direction}_error_model: {requested} -> {selected} ({reason})")
    if not lines:
        return ""
    return "\n".join(lines) + "\n"

for run_dir in run_dirs:
    cutadapt_log_files = glob.glob(os.path.join(run_dir, "intermediate/cutadapt/cutadapt_summary.log"))

    
    dada2_files = [str(snakemake.input.track_report)]

    
    need_figaro = not bool(dada2_params and str(dada2_params).strip())
    figaro_files = glob.glob(os.path.join(run_dir, "intermediate/figaro/trimParameters.json")) if need_figaro else []

    print(f"DEBUG: Run {os.path.basename(run_dir)}")
    print(f"  Cutadapt: {cutadapt_log_files}")
    print(f"  DADA2: {dada2_files}")
    print(f"  Figaro: {figaro_files} (needed={need_figaro})")

    # FIX: controlla figaro_files solo se serve
    if not cutadapt_log_files or not dada2_files or (need_figaro and not figaro_files):
        raise FileNotFoundError(
            f"Missing files in {run_dir}:\n"
            f"Cutadapt: {cutadapt_log_files}\n"
            f"DADA2: {dada2_files}\n"
            f"Figaro (needed={need_figaro}): {figaro_files}"
        )

    cutadapt_log = cutadapt_log_files[0]
    dada2_file = dada2_files[0]

    df1 = pd.read_table(cutadapt_log, sep="\t")
    df2 = pd.read_table(dada2_file).loc[:, ["sample", "reads.in", "reads.out", "dadaF", "dadaR", "merged", "nonchim"]]
    df2["sample"] = df2["sample"].str.replace(r"_R1_filtered\.fq\.gz$", "", regex=True)
    df_multi = build_denoising_table(df1, df2)

    
    trim_position = None
    max_expected_error = None
    if need_figaro:
        figaro_json = figaro_files[0]
        with open(figaro_json, "r") as fh:
            data = json.load(fh)
        d = data[0]
        trim_position = f"forward:{d['trimPosition'][0]}, reverse:{d['trimPosition'][1]}"
        max_expected_error = f"forward:{d['maxExpectedError'][0]}, reverse:{d['maxExpectedError'][1]}"

    run_reports.append({
        "run": os.path.basename(run_dir),
        "df_multi": df_multi,
        "trim_position": trim_position,
        "max_expected_error": max_expected_error,
        "error_models": format_error_models(run_dir)
    })

# Taxonomy info
tax_methods = {
    "decipher_silva138": ("DECIPHER", "Silva", "138"),
    "decipher_gtdb226": ("DECIPHER", "GTDB", "226"),
    "decipher_rdp18": ("DECIPHER", "RDP", "18"),
    "dada2_silva_genus138": ("DADA2", "Silva", "138"),
    "dada2_RDP_genus19": ("DADA2", "RDP", "19"),
    "dada2_GG2_genus09": ("DADA2", "GreenGenes2", "2024.09"),
    "dada2_RefSeq_RDPv16": ("DADA2", "RefSeq+RDP", "v16"),
    "dada2_GTDB_r202": ("DADA2", "GTDB", "r202"),
}
method, database, db_version = tax_methods.get(snakemake.params.taxonomy_method, ("Unknown", "Unknown", "Unknown"))

# Info workflow
workflow_file = snakemake.params.workflow_file
version = snakemake.params.version
start_formatted = datetime.datetime.fromisoformat(snakemake.params.start).strftime('%Y-%m-%d %H:%M:%S')
input_mtimes = [os.path.getmtime(str(path)) for path in snakemake.input if os.path.exists(str(path))]
end_timestamp = max(input_mtimes) if input_mtimes else datetime.datetime.now().timestamp()
end_formatted = datetime.datetime.fromtimestamp(end_timestamp).strftime('%Y-%m-%d %H:%M:%S')


def getDada2Params(dada2_params):
    params_list = [p.strip() for p in dada2_params.split(";") if p.strip()]

    formatted_lines = []
    for param in params_list:
        if "=" in param:
            key, val = param.split("=", 1)
            formatted_lines.append(f"{key.strip()}: {val.strip()}")
        else:
            formatted_lines.append(param.strip())

    return "\n".join(formatted_lines)

report_sections = []
for r in run_reports:
    if dada2_params and str(dada2_params).strip():
        error_model_lines = r["error_models"]
        parameters = f"""
### DADA2 User parameters
{getDada2Params(dada2_params)}
{error_model_lines}"""
    else:
        error_model_lines = r["error_models"]
        if not error_model_lines and loess_model != "NA":
            error_model_lines = f"loess_model: {loess_model}\n"
        parameters = f"""
### DADA2 Figaro parameters
trim_position: {r['trim_position']}
max_expected_error: {r['max_expected_error']}
{error_model_lines}"""

    section = f"""
## Run {r['run']}
{parameters}
### Denoising stats
{r['df_multi'].to_string(index=True)}
"""
    report_sections.append(section)

report = f"""
# Report file
Analysis started: {start_formatted}
Analysis ended: {end_formatted}

## Primers
Forward: {snakemake.params.forward_p}
Reverse: {snakemake.params.reverse_p}

{''.join(report_sections)}

## Taxonomy annotation
Method: {method}
Database: {database}
Version: {db_version}

## Ampwrap info
Workflow: {workflow_file}
Version: {version}

## Citation
generated by AmpWrap short
L. Doni, A. Marotta, L. Vezzulli, E. Bosi, AmpWrap: a one-line fully automated amplicon metabarcoding 16S and 18S rRNA gene analysis, Bioinformatics Advances, Volume 5, Issue 1, 2025, vbaf312, https://doi.org/10.1093/bioadv/vbaf312
https://github.com/LDoni/AmpWrap
"""

with open(snakemake.output.report, "w") as f:
    f.write(report)

print(f"Report written to {snakemake.output.report}")
