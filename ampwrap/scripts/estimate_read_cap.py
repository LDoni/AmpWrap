#!/usr/bin/env python3

import argparse
import os
import subprocess
import sys
import tempfile


DEPTH_GRID = [100000, 200000, 400000, 800000, 1500000]
MIN_CAP = 200000
PLATEAU_GAIN = 0.05
MAX_AUTO_CAP = 1500000


def run_count(cmd):
    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return int(result.stdout.strip() or "0")


def count_non_singleton_hashes(sample_fastq):
    p1 = subprocess.Popen(
        ["seqkit", "fx2tab", "-Q", "-s", sample_fastq],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    p2 = subprocess.Popen(["cut", "-f3"], stdin=p1.stdout, stdout=subprocess.PIPE, text=True)
    p3 = subprocess.Popen(["sort"], stdin=p2.stdout, stdout=subprocess.PIPE, text=True)
    p4 = subprocess.Popen(["uniq", "-c"], stdin=p3.stdout, stdout=subprocess.PIPE, text=True)
    p1.stdout.close()
    p2.stdout.close()
    p3.stdout.close()

    count = 0
    for line in p4.stdout:
        parts = line.split()
        if parts and int(parts[0]) >= 2:
            count += 1

    stderr1 = p1.stderr.read()
    p1.stderr.close()
    return_codes = [p.wait() for p in (p1, p2, p3, p4)]
    if any(code != 0 for code in return_codes):
        raise subprocess.CalledProcessError(
            return_codes[-1],
            "seqkit fx2tab | cut | sort | uniq",
            stderr=stderr1,
        )
    return count


def sample_complexity(input_fastq, depth, seed):
    with tempfile.NamedTemporaryFile(suffix=".fastq", delete=False) as handle:
        temp_fastq = handle.name
    try:
        subprocess.run(
            ["seqkit", "sample", "-n", str(depth), "-s", str(seed), input_fastq, "-o", temp_fastq],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return count_non_singleton_hashes(temp_fastq)
    finally:
        if os.path.exists(temp_fastq):
            os.remove(temp_fastq)


def choose_depth(total_reads, complexities):
    depths = [depth for depth, _ in complexities]
    scores = [score for _, score in complexities]

    for idx in range(len(scores) - 1):
        current_depth = depths[idx]
        current_score = scores[idx]
        next_score = scores[idx + 1]
        gain = (next_score - current_score) / max(current_score, 1)
        if current_depth >= MIN_CAP and gain < PLATEAU_GAIN:
            return current_depth, f"plateau<{PLATEAU_GAIN:.2f}"

    if total_reads > MAX_AUTO_CAP:
        return MAX_AUTO_CAP, "no_plateau_guardrail"
    return total_reads, "no_plateau_keep_all"


def main():
    parser = argparse.ArgumentParser(description="Estimate a sensible read cap for deep amplicon libraries.")
    parser.add_argument("--input", required=True, help="Input FASTQ(.gz)")
    parser.add_argument("--total-reads", required=True, type=int, help="Total reads in the input FASTQ")
    parser.add_argument("--seed", required=True, type=int, help="Deterministic seed")
    parser.add_argument("--report", required=True, help="Path for the key=value report")
    args = parser.parse_args()

    total_reads = args.total_reads
    if total_reads <= MIN_CAP:
        selected_cap = total_reads
        reason = "below_min_cap_keep_all"
        complexities = []
    else:
        candidate_depths = []
        for depth in DEPTH_GRID:
            if depth < total_reads:
                candidate_depths.append(depth)
        candidate_depths.append(min(total_reads, MAX_AUTO_CAP))
        candidate_depths = sorted(set(candidate_depths))

        complexities = [
            (depth, sample_complexity(args.input, depth, args.seed))
            for depth in candidate_depths
        ]
        selected_cap, reason = choose_depth(total_reads, complexities)

    with open(args.report, "w") as handle:
        handle.write(f"auto_cap_reason={reason}\n")
        handle.write(f"auto_cap_total_reads={total_reads}\n")
        handle.write(f"auto_cap_selected={selected_cap}\n")
        if complexities:
            handle.write(
                "auto_cap_curve="
                + ";".join(f"{depth}:{score}" for depth, score in complexities)
                + "\n"
            )
        else:
            handle.write("auto_cap_curve=\n")

    sys.stdout.write(str(selected_cap))


if __name__ == "__main__":
    main()
