# Sandboxed rebuild of the original Lean RH proof

A third independent rebuild of Levent Alpöge's Lean proof of the Riemann Hypothesis, run on a
24-core / 62 GB Linux box in a Docker sandbox with no network. This branch holds only the
scripts and results. The proof itself is on `main` and `original` upstream at
[leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis).

Earlier rebuilds this one checks against:

- Andrew Sutherland's original build and his later sandboxed `lake build`
  (<https://math.mit.edu/~drew/grh/>). That sandboxed build reproduced the solution export
  `5ea74b91…244e` byte for byte.
- The Lean FRO / Mathlib Initiative statement:
  <https://leanprover-community.github.io/blog/posts/riemann-hypothesis/>

What this run adds: a different sandbox (Docker `--network none`, read-only root, all
capabilities dropped, rather than bubblewrap), different hardware, and a file-by-file comparison
of every compiled `.olean` against both of Sutherland's manifests. The export step needs 163 GB
of RAM, so this box can't make one.

## Setup

- Source: `https://alpo.ge/lean.tar.gz.part01..14`, joined, then extracted.
- Lean `v4.33.1` via elan, commit `819816b2`. In the container it is mounted read-only at
  `/opt/lean`.
- The project root is mounted at `/home/ubuntu/grh/src/lean`, the same path as Sutherland's
  builds. In Lean 4.33.1 a `.olean` stores the absolute path of its source file for every
  linter message, so only builds at the same path can match file by file.
- Mathlib `0df444a3` plus its official cache, fetched in a container with network access
  (`run.sh net`). Every build step runs with `run.sh nonet`.

## Scripts

| File | Role |
|---|---|
| `scripts/Dockerfile` | `debian:trixie-slim` + git, ca-certificates, procps, curl |
| `scripts/run.sh` | runs a command in the container at Sutherland's path; `net` or `nonet` |
| `scripts/run2.sh` | the same for another work directory (used for lean4export and the challenge) |
| `scripts/smoke-build.sh` | 20-minute capped `lake build Lemmata`, plus the `.setup.json` cleanup loop |
| `scripts/full-build-inner.sh` | `lake build Main` inside the sandbox, with the cleanup loop and a stall watchdog (kills Lake after 30 min with no new `.olean`) |
| `scripts/full-build-driver.sh` | host-side loop that restarts the inner script up to 12 times |
| `scripts/compare-oleans.sh` | hashes every built `.olean` and compares it with both of Sutherland's manifests |

## Results so far (2026-11-24)

| Check | Result |
|---|---|
| Joined archive | 239,275,554 bytes, sha256 `9631b4f020199e580ba86178cb56c6e9b09f690c2369a80dc4334aa93f49c7fc` (matches) |
| Archive `lean/` vs upstream `original` branch (`40e56bab`) | identical (`diff -r`), 175,187 `.lean` files |
| `--network none` sandbox | DNS and HTTPS both blocked (checked at the start of every attempt) |
| lean4export tag `v4.33.0` (`15f6055e`) built with 4.33.1, offline | binary sha256 `805ab4cc6a88dcef109644d201c3142261f524aecaf58b04913a9f029e21e9b5`, the same as Sutherland's |
| `Challenge.lean` at upstream `e7c8972c` (4.33.1 pins), built offline in a separate directory | `challenge.export` 350,862,311 bytes, sha256 `bd484ac9886a96f26b1d9a7a59ebd45b7a70d102c015d4f31f9302bbdd6ab2b9` (matches) |
| Smoke build (`lake build Lemmata`, 836 project modules, about 4 min) | exit 0; 836 of 836 `.olean` files byte-identical to `project-oleans.sha256` |
| Full `lake build Main`, started 2026-11-24 21:18 UTC | in progress; the first 2,609 `.olean` files are byte-identical |

## Still to do

- [ ] Full build finishes; record wall time and the number of restarts
- [ ] `compare-oleans.sh` on all 175,187 files. Expect every file to match, except possibly
      `Formalism/LocalToGlobal/SiegelLatticeTheory/CokernelGLCounts/RankPointCounts/LocModel.olean`.
      Sutherland traced that file to a parallel-elaboration race in Lean ≤ 4.35 (lean4#15498). If it
      differs, it should match one of his two manifests.
- [ ] `#print axioms` on the five theorems in `Main.lean`: expect only `propext`,
      `Classical.choice`, `Quot.sound`

## Reproduce

```bash
for i in $(seq -w 1 14); do curl -sSfO https://alpo.ge/lean.tar.gz.part$i; done
cat lean.tar.gz.part{01..14} > lean.tar.gz && sha256sum lean.tar.gz   # 9631b4f0…
mkdir -p ~/rh/work/grh/src && tar -xzf lean.tar.gz -C ~/rh/work/grh/src   # gives …/grh/src/lean
docker build -t rhcheck-sandbox:1 scripts/
cp scripts/full-build-inner.sh ~/rh/work/
scripts/run.sh net "lake exe cache get"         # Mathlib only; the original tree has no project cache
scripts/full-build-driver.sh                    # hours; restarts on stalls
scripts/compare-oleans.sh                       # needs Sutherland's two manifests in ~/rh/ref/
```

The scripts expect `~/rh/sandbox/` (scripts) and `~/rh/work/` (project) layouts; adjust the
paths for your own machine.
