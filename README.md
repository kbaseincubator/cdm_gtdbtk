# cdm_gtdbtk

CTS (CDM Task Service) job wrapper for [GTDB-Tk](https://github.com/Ecogenomics/GTDBTk), the standard toolkit for taxonomic classification of bacterial and archaeal genomes based on the [GTDB](https://gtdb.ecogenomic.org/).

## Container

Wraps the official [`ecogenomic/gtdbtk`](https://hub.docker.com/r/ecogenomic/gtdbtk) image (v2.7.2), which is the matching binary for the GTDB R232 reference DB.

Published to `ghcr.io/kbaseincubator/cdm_gtdbtk`.

**Entrypoint:** `gtdbtk`. Append a subcommand and flags as arguments (most commonly `classify_wf`).

**Reference data:** Required, ~110 GB. CTS mounts the GTDB-Tk R232 bundle at `/ref_data`. The image bakes `GTDBTK_DATA_PATH=/ref_data` so callers do NOT need to set it themselves. The unpacked layout under `/ref_data` follows the upstream GTDB-Tk DB structure (`split/`, `pplacer/`, `markers/`, `mash/`, `radii/`, etc.).

Single image (not split into siblings) because gtdbtk always needs the GTDB reference DB. There is no useful "without refdata" mode. See the `cdm_tool_skeleton` README section on when to split tools for the design rationale.

## Usage via CTS

```python
job = tscli.submit_job(
    "ghcr.io/kbaseincubator/cdm_gtdbtk:0.1.0@sha256:<digest>",
    input_files,                    # nucleotide assemblies (.fna or .fna.gz)
    "cts/io/<user>/output/gtdbtk/run1",
    cluster="kbase",
    declobber=True,
    output_mount_point="/out",
    args=[
        "classify_wf",
        "--genome_dir", "<input dir, see below>",
        "--out_dir", "/out",
        "--cpus", "8",
        "--extension", "fna.gz",
        tscli.insert_files(),       # see CTS docs on how input_files are mounted
    ],
    num_containers=1,                # classify_wf operates on a genome directory, not one-at-a-time
    cpus=8,
    memory="64GB",
    runtime="PT4H",
)
```

Note: `classify_wf` is designed to take a directory of genomes, not one per container. Submit all assemblies in one container so the workflow can build a single marker-gene alignment + place them on the same tree.

For a faster run that skips the ANI screen step (which adds 1-2 hours but produces the closest-reference and ANI fields), pass `--skip_ani_screen`.

## Output

Per run, gtdbtk classify_wf produces:
- `gtdbtk.bac120.summary.tsv`: bacterial classifications (one row per input bacterial genome)
- `gtdbtk.ar53.summary.tsv`: archaeal classifications (if any inputs are archaea)
- `align/`, `identify/`, `classify/`: per-stage intermediates
- `gtdbtk.log`: run log
- `gtdbtk.warnings.log`: any warnings (e.g., genomes with marker counts below threshold)

Summary columns: `user_genome`, `classification`, `closest_genome_reference`, `closest_genome_ani`, `closest_genome_af`, `msa_percent`, `red_value`, `warnings`, etc. The classification string is the full GTDB taxonomy (`d__Bacteria;p__Pseudomonadota;c__Gammaproteobacteria;...`).
