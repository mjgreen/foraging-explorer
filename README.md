# Foraging explorer

A local R/Shiny demonstration of two rules: choose any tree at random, or remember
visited trees and avoid revisits. Explore repeated searches with reproducible seeds.

This public distribution contains **synthetic comparison curves only**. The two
reference panels are generated illustrations, not human observations, fitted models
or results from the published study. No participant trajectories are included.

## Run with Docker

Install Docker, download this repository using **Code → Download ZIP**, extract it,
and open a terminal in the extracted folder:

```sh
docker build -t foraging-explorer .
docker run --rm -p 127.0.0.1:3842:3838 --read-only --tmpfs /tmp:rw,size=256m --memory=1g --cpus=2 foraging-explorer
```

Open **http://127.0.0.1:3842** in a browser. Stop with Ctrl+C. The first build
downloads R packages from public CRAN and compiles them; allow several minutes.
The public Rocker R 4.5.1 base is pinned by digest. No private registry, account,
API key, Cloudflare service or connection to Matt's computer is needed.

## Run with R

Use R 4.5.1 for the tested runtime. Other versions may work but are not covered by
the recorded checks. On Windows, installing packages from source may require the
matching Rtools; macOS may require command-line build tools. Linux needs a C/C++/
Fortran compiler and the development tools required to build R packages, including
`pkg-config` and the zlib headers (`zlib1g-dev` on Debian/Ubuntu).

From this folder:

```sh
Rscript --vanilla scripts/setup.R
Rscript --vanilla scripts/run.R
```

Open **http://127.0.0.1:3842**. Packages are installed into `.foraging-library`
inside this folder, leaving your global R configuration unchanged. `renv.lock`
pins the complete runtime dependency set. The native launcher listens only on
loopback by default; `--port=3844` selects another unprivileged port.

## Explore

- Start with **Compare both**. Each line is one simulated or synthetic search.
- Change the number of simulations and seed, then press **Run simulations**.
- **New simulations** increments the seed. Switching views reuses existing runs.
- Memory remembers fruitless trees too. Fruit can be collected only once.
- Every forest has 30 trees and 15 fruit. Agents stop collecting at 10 fruit;
  the display continues to move 35.

Both agents choose globally. Rearranging trees into patches therefore does not
change expected performance for the same tree/fruit counts. The synthetic
references deliberately have different illustrative timing distributions; they
are not evidence that either agent explains human search.

## Checks and synthetic provenance

```sh
Rscript --vanilla -e '.libPaths(c(normalizePath(".foraging-library"), .libPaths())); source("tests/test_simulation.R"); source("tests/test_demo.R")'
```

The checks exercise memory, depletion, stopping, seeds, nested runs, data boundaries,
synthetic labels and plot construction. `tests/test_server.R` additionally checks
reactive behaviour when the optional `testthat` package is available.

`python3 scripts/generate_demo.py` reproduces `data/synthetic-curves.csv` without
reading any study archive. It creates 100 trajectories per reference, with ten
fruit moves selected by a documented SHA-256 ordering. All searches reach ten
fruit and retain their final tally through move 35. `PUBLIC-MANIFEST.json` records
the exported files and their hashes; `.git`, host configuration, deployment units,
private data, runtime libraries and review captures are excluded.

## Authorship and research context

App and model by Matt Green, developed from his R/simecol demonstration.
The simulations are exploratory. Read the separate
[visual-foraging paper](https://doi.org/10.1007/s10339-025-01261-0) for published
research; this download does not reproduce its human benchmark. No application
software licence has yet been specified. See `RIGHTS.md` for the current rights
notice and third-party dependency attribution; no new licence grant is made here.
