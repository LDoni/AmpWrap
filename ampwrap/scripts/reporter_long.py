import pandas as pd
import json
import os
import datetime

# Input file paths
cutadapt_path = snakemake.input.get("cutadapt", None)
seqkit_pre = snakemake.input.seqkit_pre
seqkit_post = snakemake.input.seqkit_post

# Read raw and trimmed read stats
df_pre = pd.read_table(seqkit_pre)
df_post = pd.read_table(seqkit_post)

# Extract sample names
df_pre["sample"] = df_pre["file"].apply(lambda x: x.split("/")[-1].replace(".fastq", ""))
df_post["sample"] = df_post["file"].apply(lambda x: x.split("/")[-1].replace("-nanofilt.fastq", ""))

# Select relevant columns
df_pre = df_pre[["sample", "num_seqs", "sum_len", "min_len", "avg_len", "max_len"]]
df_post = df_post[["sample", "num_seqs", "sum_len", "min_len", "avg_len", "max_len"]]

# Rename for clarity
df_pre.columns = ["sample", "raw_num_seqs", "raw_sum_len", "raw_min_len", "raw_avg_len", "raw_max_len"]
df_post.columns = ["sample", "trim_num_seqs", "trim_sum_len", "trim_min_len", "trim_avg_len", "trim_max_len"]

# Merge raw and trimmed
df = pd.merge(df_pre, df_post, on="sample", how="outer")

# Handle optional cutadapt input
has_cutadapt = cutadapt_path and os.path.exists(cutadapt_path)
if has_cutadapt:
    df_cutadapt = pd.read_table(cutadapt_path)
    df_cutadapt.columns = ["sample", "reads_retained", "bps_retained"]
    df_cutadapt["reads_retained"] = df_cutadapt["reads_retained"].str.replace("%", "").astype(float)
    df_cutadapt["bps_retained"] = df_cutadapt["bps_retained"].str.replace("%", "").astype(float)
    df = pd.merge(df, df_cutadapt, on="sample", how="left")

# Create columns
columns = [
    ("raw-reads", "#seqs"),
    ("raw-reads", "Sum Length"),
    ("raw-reads", "Min Length"),
    ("raw-reads", "Avg Length"),
    ("raw-reads", "Max Length"),
]
if has_cutadapt:
    columns += [
        ("cutadapt", "Reads Retained (%)"),
        ("cutadapt", "Bps Retained (%)"),
    ]
columns += [
    ("trimmed-reads", "#seqs"),
    ("trimmed-reads", "Sum Length"),
    ("trimmed-reads", "Min Length"),
    ("trimmed-reads", "Avg Length"),
    ("trimmed-reads", "Max Length"),
]

# Build final table
data = []
for _, row in df.iterrows():
    row_data = [
        row.get("raw_num_seqs", ""),
        row.get("raw_sum_len", ""),
        row.get("raw_min_len", ""),
        row.get("raw_avg_len", ""),
        row.get("raw_max_len", ""),
    ]
    if has_cutadapt:
        row_data += [
            row.get("reads_retained", ""),
            row.get("bps_retained", "")
        ]
    row_data += [
        row.get("trim_num_seqs", ""),
        row.get("trim_sum_len", ""),
        row.get("trim_min_len", ""),
        row.get("trim_avg_len", ""),
        row.get("trim_max_len", ""),
    ]
    data.append(row_data)

df_final = pd.DataFrame(data, columns=pd.MultiIndex.from_tuples(columns), index=df["sample"])
df_final.index.name = "Sample"

# Convert table to markdown
report_table_md = df_final.reset_index().to_csv(sep='\t', index=False)

# Taxonomy DB info
assign_taxonomy_method = snakemake.params.tax_db
taxonomy_info = {
    "silva": ("Silva", "138.1"),
    "rdp": ("RDP", "11.5"),
    "emu": ("EMU", "Default DB")
}
db_name, version = taxonomy_info.get(assign_taxonomy_method, ("Unknown", "N/A"))

# Format timestamps
start_formatted = datetime.datetime.fromisoformat(snakemake.params.start).strftime('%Y-%m-%d %H:%M:%S')
end_formatted = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

# Initialize report lines
report_lines = [
    "# Report file",
    f"Analysis started: {start_formatted}",
    f"Analysis ended: {end_formatted}",
    ""
]

# Add primers section if cutadapt is used
if snakemake.params.to_cutadapt:
    report_lines.append("## Primers")
    if snakemake.params.forward_p:
        report_lines.append(f"- Forward: `{snakemake.params.forward_p}`")
    if snakemake.params.reverse_p:
        report_lines.append(f"- Reverse: `{snakemake.params.reverse_p}`")
    if snakemake.params.RC_RVS:
        report_lines.append(f"- Reverse Complement Reverse: `{snakemake.params.RC_RVS}`")
    report_lines.append("")

# Add NanoFilt and EMU parameters
report_lines.extend([
    "## NanoFilt Parameters",
    f"- Minimum Length: `{snakemake.params.nl_min_len}`",
    f"- Maximum Length: `{snakemake.params.nl_max_len}`",
    f"- Minimum Quality: `{snakemake.params.nl_min_qual}`",
    "",
    "## EMU Taxonomy Parameters",
    f"- Filter species with relative abundance below: `{snakemake.params.emu_min_ab}`",
    f"- Database: `{db_name}`",
    f"- Version: `{version}`",
])

# Add Trimming Method section if specified
if hasattr(snakemake.params, 'trimming_method') and snakemake.params.trimming_method:
    report_lines.extend([
        "",
        "## Trimming Method",
        f"- Method: `{snakemake.params.trimming_method}`"
    ])

# Add summary table and footer
report_lines.extend([
    "",
    "## Summary Table",
    report_table_md,
    "",
    "## Citation",
    "Generated by AmpWrap" ,
    "",
    "https://github.com/LDoni/AmpWrap"
])

# Write final report
with open(snakemake.output.report, "w") as f:
    f.write("\n".join(report_lines))
