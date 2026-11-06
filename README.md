# cdm_gtdbtk

CTS (CDM Task Service) job wrapper for [GTDB-Tk](https://github.com/Ecogenomics/GTDBTk), the standard toolkit for taxonomic classification of bacterial and archaeal genomes based on the [GTDB](https://gtdb.ecogenomic.org/).

## Container

Wraps the official [`ecogenomic/gtdbtk`](https://hub.docker.com/r/ecogenomic/gtdbtk) image (v2.7.2), which is the matching binary for the GTDB R232 reference DB.

Published to `ghcr.io/kbaseincubator/cdm_gtdbtk`.

**Entrypoint:** `gtdbtk`. Append a subcommand and flags as arguments (most commonly `classify_wf`).

**Reference data:** Required. CTS mounts the GTDB-Tk R232 bundle (refdata ID `bb6352b4-b86f-4e3d-a858-4bc77327ab13`) at `/ref_data`; it unpacks to `/ref_data/release232/`. The image sets `GTDBTK_DATA_PATH=/ref_data/release232`, so callers do NOT set it.

Single image (not split into variants) because gtdbtk always needs the GTDB reference DB. There is no useful "without refdata" mode. See the `cdm_tool_skeleton` README section on when to split tools for the design rationale.

## Usage via CTS

See `demo.ipynb` in this repo for an end-to-end run.

```python
job = tscli.submit_job(
    "ghcr.io/kbaseincubator/cdm_gtdbtk:0.1.1@sha256:3dd3ae33859f7719b95f69c286d7a631863c95799157824faa5dfcc6d9233673",
    input_files,                    # nucleotide assemblies, all with the same extension
    "cts/io/<your_username>/output/gtdbtk/run1",
    cluster="kbase",
    declobber=True,
    input_mount_point="/input",     # classify_wf reads a directory, so mount inputs at a known path
    output_mount_point="/out",
    args=[
        "classify_wf",
        "--genome_dir", "/input",
        "--out_dir", "/out",
        "--cpus", "8",
        "--extension", "fna.gz",    # must match EVERY input file
    ],
    num_containers=1,               # one container, so all genomes share one alignment and tree
    cpus=8,
    memory="128GB",
    runtime="PT6H",
)
```

Do **not** add `tscli.insert_files()`: `classify_wf` takes no positional arguments and exits with a usage error. It finds the genomes through `--genome_dir`.

`--extension` must match every input. Files with a different extension (e.g. `.fna` in a `fna.gz` run) are skipped and the job still succeeds, so check that the summary has one row per input genome.

### Memory and runtime

Genomes that closely match a GTDB representative are classified by the ANI screen; in a test, 4 such genomes finished in about a minute at a 15.7 GB peak. Genomes that do not match go through pplacer, which upstream documents as needing about 140 GB for bacteria. That path has **not yet been validated on CTS**; request 150 GB for submissions that may include novel genomes or MAGs. To cut pplacer memory use `--scratch_dir`; `--pplacer_cpus` does not reduce it.

## Output

Per run, gtdbtk classify_wf produces:
- `gtdbtk.bac120.summary.tsv`: bacterial classifications (one row per input bacterial genome)
- `gtdbtk.ar53.summary.tsv`: archaeal classifications (if any inputs are archaea)
- `align/`, `identify/`, `classify/`: per-stage intermediates. `classify/` contains byte-identical copies of the summary TSVs, so importers should read only the top-level ones.
- `gtdbtk.log`: run log
- `gtdbtk.warnings.log`: any warnings (e.g., genomes with marker counts below threshold)

Summary columns: `user_genome`, `classification`, `closest_genome_reference`, `closest_genome_ani`, `closest_genome_af`, `msa_percent`, `red_value`, `warnings`, etc. The classification string is the full GTDB taxonomy (`d__Bacteria;p__Pseudomonadota;c__Gammaproteobacteria;...`). `msa_percent` and `red_value` are empty for genomes classified by the ANI screen.
