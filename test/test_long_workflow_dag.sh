#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_parent="$(mktemp -d)"
test_root="$test_parent/case with spaces"
mkdir -p "$test_root"
trap 'find "$test_parent" -depth -delete' EXIT

input_dir="$test_root/input"
output_dir="$test_root/output"
config_path="$test_root/config.yaml"
mkdir -p "$input_dir"

sequence="ACGTACGTACGTACGTAAAAAAAAAAAAAAAAAAAATGCATGCATGCATGCA"
quality="$(printf '%*s' "${#sequence}" "" | tr ' ' 'I')"
for sample in sample-a sample-nanofilt; do
  printf '@read1\n%s\n+\n%s\n' "$sequence" "$quality" > "$input_dir/$sample.fastq"
done

{
  printf 'input_dir: input\n'
  printf 'output_dir: output\n'
  printf 'tax_db: silva-138.2\n'
  printf 'db_dir: db\n'
  printf 'logs: output/logs\n'
  printf 'file_extension: fastq\n'
  printf 'sample_names:\n'
  printf '  - sample-a\n'
  printf '  - sample-nanofilt\n'
  printf 'threads: 2\n'
  printf 'nl_min_len: 100\n'
  printf 'nl_max_len: 2000\n'
  printf 'nl_min_qual: 7\n'
  printf 'emu_min_ab: 0.0001\n'
  printf 'forward_primer: ACGTACGTACGTACGT\n'
  printf 'reverse_primer: TGCATGCATGCATGCA\n'
  printf 'keep_counts: false\n'
} > "$config_path"

summary_path="$output_dir/intermediate/cutadapt/cutadapt_summary.tsv"
pushd "$test_root" > /dev/null
snakemake \
  --snakefile "$repo_root/ampwrap/snakefile.long" \
  --configfile "$config_path" \
  --cores 1 \
  "$summary_path"

grep -Fx $'sample\treads retained\tbps retained' "$summary_path"
grep -Fx $'sample-a\t100.0%\t38.5%' "$summary_path"
grep -Fx $'sample-nanofilt\t100.0%\t38.5%' "$summary_path"

dry_run_log="$test_root/dry-run.log"
snakemake \
  --snakefile "$repo_root/ampwrap/snakefile.long" \
  --configfile "$config_path" \
  --cores 2 \
  --dry-run \
  > "$dry_run_log"

if grep -Fq "combined.fastq" "$dry_run_log"; then
  echo "Unexpected synthetic combined.fastq dependency" >&2
  exit 1
fi

grep -Fq "silva-138.2" "$dry_run_log"
popd > /dev/null

db_info="$(python "$repo_root/ampwrap/AmpWrap_long" --db-info)"
for database in silva-138.2 unite-fungi unite-all emu-2026; do
  grep -Fq "$database" <<< "$db_info"
done

echo "Long-workflow DAG and Cutadapt summary regression test passed"
