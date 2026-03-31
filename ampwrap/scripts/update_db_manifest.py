#!/usr/bin/env python3

import argparse
import csv
import datetime as dt
import os
from tempfile import NamedTemporaryFile


FIELDS = ["category", "name", "filename", "md5", "source_url", "local_path", "last_checked"]


def parse_args():
    parser = argparse.ArgumentParser(description="Update AmpWrap DB manifest.")
    parser.add_argument("--manifest", required=True, help="Path to manifest.tsv")
    parser.add_argument("--category", required=True, help="Database category, e.g. dada2/decipher/emu")
    parser.add_argument("--name", required=True, help="Logical database name")
    parser.add_argument("--filename", required=True, help="Stored filename")
    parser.add_argument("--md5", default="", help="Expected MD5 checksum")
    parser.add_argument("--source-url", default="", help="Source URL")
    parser.add_argument("--local-path", required=True, help="Local file or directory path")
    return parser.parse_args()


def read_rows(path):
    if not os.path.exists(path):
        return []
    with open(path, newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        return list(reader)


def write_rows(path, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with NamedTemporaryFile("w", delete=False, dir=os.path.dirname(path), newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS, delimiter="\t")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in FIELDS})
        tmp_path = handle.name
    os.replace(tmp_path, path)


def main():
    args = parse_args()
    rows = read_rows(args.manifest)
    key = (args.category, args.name, args.filename)
    timestamp = dt.datetime.now().isoformat(timespec="seconds")

    updated = False
    for row in rows:
        if (row.get("category"), row.get("name"), row.get("filename")) == key:
            row.update({
                "md5": args.md5,
                "source_url": args.source_url,
                "local_path": os.path.abspath(args.local_path),
                "last_checked": timestamp,
            })
            updated = True
            break

    if not updated:
        rows.append({
            "category": args.category,
            "name": args.name,
            "filename": args.filename,
            "md5": args.md5,
            "source_url": args.source_url,
            "local_path": os.path.abspath(args.local_path),
            "last_checked": timestamp,
        })

    rows.sort(key=lambda row: (row.get("category", ""), row.get("name", ""), row.get("filename", "")))
    write_rows(args.manifest, rows)


if __name__ == "__main__":
    main()
