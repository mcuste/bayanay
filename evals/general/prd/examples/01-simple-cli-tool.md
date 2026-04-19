# PRD-001: CSV-to-JSON CLI Converter

- **ID**: PRD-001
- **Status**: Draft
- **Author**: —
- **Created**: 2026-04-19
- **Last Updated**: 2026-04-19

## Problem

Data engineers routinely convert CSV files to JSON as part of ETL pipelines, data migrations, and system integrations. Current workflows rely on ad-hoc scripts (Python one-liners, jq gymnastics) or GUI tools that don't compose with Unix pipelines. These approaches break on large files (multi-GB) due to full-file memory loading, lack reproducible column mapping configuration, and require per-engineer maintenance. Teams waste time debugging one-off scripts instead of moving data.

## Personas & Use Cases

- **Pipeline Engineer** (builds and maintains ETL jobs): Needs a reliable, scriptable converter they can drop into shell pipelines (`cat data.csv | csvjson | upload-tool`). Runs unattended in cron jobs — must not silently corrupt data or OOM on large inputs.
- **Data Analyst** (occasional bulk conversion): Receives CSV exports from vendors or internal systems with inconsistent column names. Needs to remap columns to match the target schema without writing code each time.

## Goals & Scope

- **Must have**: Stream-based CSV→JSON conversion that handles files larger than available RAM. Config-file-driven column mappings (rename, exclude, reorder). Output to stdout (default) or a named file. Valid JSON output for all well-formed CSV input.
- **Should have**: Support for common CSV dialects (custom delimiters, quote characters, encoding). Progress indication on stderr for large files when output is a file.
- **Non-goals**: JSON→CSV reverse conversion — different tool, different concerns. GUI or interactive mode — this is a pipeline component. Data validation or transformation beyond column mapping (type coercion, filtering) — belongs in downstream tools.

## User Stories

- As a **Pipeline Engineer**, I want to convert a 5 GB CSV file to JSON so that I can feed it into a JSON-consuming downstream service.
  - **Acceptance**: Memory usage stays below 100 MB regardless of input file size. Output is a valid JSON array.
  - **Scenario**: Engineer runs `csvjson --input transactions-5gb.csv --output transactions.json`. Process completes with constant memory usage. Output file contains a valid JSON array with one object per CSV row.

- As a **Pipeline Engineer**, I want to pipe CSV data from stdin and receive JSON on stdout so that I can compose the tool with other Unix utilities.
  - **Acceptance**: `echo "a,b\n1,2" | csvjson` produces `[{"a":"1","b":"2"}]` on stdout. Exit code 0 on success, non-zero on malformed input.
  - **Scenario**: Engineer runs `db-export --table users | csvjson | jq '.[] | select(.active=="true")' | post-to-api`. Each tool in the pipeline processes data as it arrives without buffering the full dataset.

- As a **Data Analyst**, I want to apply a column mapping config file so that vendor CSV columns match our internal schema without editing the source file.
  - **Acceptance**: A config file specifies rename rules (`vendor_id → id`), excluded columns, and output column order. The tool applies mappings and the output JSON uses the mapped names.
  - **Scenario**: Analyst creates `vendor-mapping.yaml` with `mappings: { "Vendor ID": "id", "Full Name": "name" }` and `exclude: ["internal_ref"]`. Runs `csvjson --config vendor-mapping.yaml --input vendor-export.csv`. Output JSON objects have keys `id` and `name`; `internal_ref` is absent.

## Behavioral Boundaries

- **File size**: No upper limit — streaming architecture. Memory stays under 100 MB for any input size.
- **Malformed rows**: Tool logs a warning to stderr with the line number and continues processing. Exit code indicates partial failure.
- **Config file errors**: Tool exits immediately with a descriptive error message before processing any input. No partial output.
- **Column name conflicts**: If a mapping produces duplicate column names, tool exits with an error listing the conflicting names.

## Non-Functional Requirements

- **Performance**: Throughput ≥ 50 MB/s on commodity hardware (single core). Memory usage ≤ 100 MB regardless of input size.
- **Reliability**: Atomic file output — partial output on crash must not leave a corrupt file at the target path (write to temp, rename on completion).

## Risks & Open Questions

- **Risk**: CSV dialect detection across vendors is unreliable — likelihood: M — mitigation: require explicit dialect flags rather than auto-detection; provide sensible defaults matching RFC 4180.
- **Dependency**: Config file format choice (YAML, TOML, JSON) affects which dependencies ship with the binary — lightweight format preferred.
- [ ] Should the tool support NDJSON (one JSON object per line) as an alternative output format? Pipeline engineers often prefer line-delimited JSON for streaming consumers.
- [ ] What character encoding should be assumed for input? UTF-8 only, or support for legacy encodings (Latin-1, Shift-JIS)?

## Success Metrics

- Adoption: ≥ 3 internal pipelines replace custom scripts within 1 month of release
- Reliability: Zero data corruption incidents in first 3 months of production use
- Performance: Converts a 1 GB CSV file in under 20 seconds on standard CI hardware
