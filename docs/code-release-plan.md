# Code releases for papers

Goal: one GitHub release per analysis repository, pinned to the commit used
for the paper, so `code` in `papers.toml` can point at a frozen version.

Turn on the Zenodo GitHub integration for a repo *before* creating its
release if you also want a citable DOI (Zenodo archives on release publish).

After a release exists, change that paper's `code` to the release URL
(`https://github.com/<owner>/<repo>/releases/tag/<tag>`), as already done
for `vegayon-ltcf`.

Once Zenodo has archived the release, add a DOI badge to the repository's
README using the *concept* DOI (it always resolves to the latest version). If
the README is generated from a `README.Rmd` or `README.qmd`, add it there too.

```md
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.<concept>.svg)](https://doi.org/10.5281/zenodo.<concept>)
```

Archived repositories are read-only on GitHub: Zenodo cannot install its
webhook (the toggle fails with a 400) and releases cannot be created. For now
their `code` links the repository itself.

## Status

| Paper key | Repository | Pinned version | Status |
| --- | --- | --- | --- |
| vegayon-ltcf | UofUEpiBio/epicenter | `30aug2026` (Accepted version) | Release exists; `code` already points to it |
| vegayon2020aphylo | USCbiostats/aphylo-simulations | `348420d` (2020-11-16, HEAD) | Released `paper-ploscb-2021`, DOI 10.5281/zenodo.23540355; `code` points to it; README badge (concept 10.5281/zenodo.23540354, `f0c1d12`) |
| tanakaImaginaryNetworkMotifs2024 | gvegayon/imaginary-structures | `0487d7d` (2023-09-18) | Repo is archived (read-only: no release, no Zenodo hook). `code` links the repo. To release: unarchive, enable Zenodo, release, re-archive |
| ouellet2022 | gvegayon/use_of_force | `be42cad` (2021-12-04, HEAD, revision 1) | Released `paper-jqc-2022`, DOI 10.5281/zenodo.23540357; `code` points to it; README badge (concept 10.5281/zenodo.23540356, `22f8b33`) |
| Valente2019 | gvegayon/fctc | `9ef7494` (2019-01-22, HEAD) | Released `paper-ssm-2019`, DOI 10.5281/zenodo.23540479 (same concept DOI as `v0.1`, 10.5281/zenodo.1311860); `code` points to it; README badge switched from the `v0.1` DOI to the concept DOI (`8347d75`) |
| vegayonPowerMulticollinearitySmall2023a | gvegayon/jasa-comment-2023 | `95ac1e7` (2023-08-29, HEAD) | Released `paper-jasa-2023`, DOI 10.5281/zenodo.23540361; `code` points to it; README badge (concept 10.5281/zenodo.23540360, `8b57788`) |
| yon2019exponential | muriteams/ergmito-simulations | `349fefe` (2020-05-05, last analysis commit) | Released `paper-socnet-2021`, DOI 10.5281/zenodo.23540363; `code` points to it; README badge (concept 10.5281/zenodo.23540362, `8e8812f`). Manuscript source: muriteams/ergmito-paper `5623f8b` |
| najafzadehkhoeiMachineGeneralizeLearning2025a | UofUEpiBio/Calibrate_ABM | `66e1d29` (2025-07-31, before arXiv v1) | Repo is archived (read-only: no release, no Zenodo hook). `code` links the repo. To release: unarchive, enable Zenodo, release, re-archive |
| vegayon-geese | USCbiostats/geese-simulations | tag `21sep2021` | Unpublished; release once the paper is out |
| johnsonBayesianGenerativeModeling2026 | CDCgov/wastewater-informed-covid-forecasting | paper cites wwinference `v0.1.1` | External org; nothing to do |
| lesslerWhyEpidemicRisk2026 | ACCIDDA/wc-risk-assessment | `ca5d2f3` (only commit) | External org; ask maintainers |
| VegaYon2019a / VegaYon2019b / VegaYon2021rgexf / meyerEpiworldRFastAgentBased2023 | fmcmc / slurmR / rgexf / epiworldR | JOSS archive (Zenodo) | Software papers; JOSS already archives the reviewed version |
| VegaYon2019c | gvegayon/parallel | Stata Journal version | Software paper; optional |
| vegayonDiscreteExponentialFamilyModels2022 | UofUEpiBio/defm | package | Paper cites the package repo |
| RePEc:sdp:sdpwps:57 | gvegayon/cnu | `a31056b` (README install pin) | Optional |

## Commands

Run from any machine with `gh` authenticated as an account that can write to
each repository. `--target` creates the tag at that commit.

```sh
# Only for archived repos; unarchive and enable Zenodo first, re-archive after.
gh release create paper-socnet-2024 --repo gvegayon/imaginary-structures \
  --target 0487d7da555c76acf2db210041a1f8034baea209 \
  --title "Version used in Tanaka & Vega Yon (2024), Social Networks" \
  --notes "Code and data for https://doi.org/10.1016/j.socnet.2023.11.005"

gh release create paper-arxiv-2025 --repo UofUEpiBio/Calibrate_ABM \
  --target 66e1d291e90469a3210405127b2b47bd0d4db567 \
  --title "Version used in Najafzadehkhoei et al. (2025), arXiv:2509.07013" \
  --notes "Code for https://doi.org/10.48550/arXiv.2509.07013"
```

## Not matched

No public repository found (or the paper is not code-based): quintanilla2013estudio,
repetto2013impacto, FabregaLacoa2013, Bell2019, DelaHaye2019, Valente2020,
Hancean2022, panahiVeteranPerspectivesEpilepsy2023,
loveCharacterizingSpatiotemporalVariation2023, sargentAssessingDynamicsPrEP2024,
piombo2025, mohammadiNovelApproachClassifying2025c,
milandoVisionEstimationInstantaneous2026, vegayonPracticalGuidelinesReflections2026,
duongIncorporatingSocialDeterminants2024, visnovskyMultidrugResistantOrganism2026,
heCaseStudyAccessible2026.

maryeHiddenBurdenMeasles2026 cites github.com/EpiForeSITE/measles-hidden-burden,
which is not public yet; add `code` once it is.
