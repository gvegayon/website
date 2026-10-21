# Code releases for papers

Goal: one GitHub release per analysis repository, pinned to the commit used
for the paper, so `code` in `papers.toml` can point at a frozen version.

Turn on the Zenodo GitHub integration for a repo *before* creating its
release if you also want a citable DOI (Zenodo archives on release publish).

After a release exists, change that paper's `code` to the release URL
(`https://github.com/<owner>/<repo>/releases/tag/<tag>`), as already done
for `vegayon-ltcf`.

## Status

| Paper key | Repository | Pinned version | Status |
| --- | --- | --- | --- |
| vegayon-ltcf | UofUEpiBio/epicenter | `30aug2026` (Accepted version) | Release exists; `code` already points to it |
| vegayon2020aphylo | USCbiostats/aphylo-simulations | `348420d` (2020-11-16, HEAD) | Release to create. Tag `rev-1-ploscompbio` (c8e2632) is the revision, not the final |
| tanakaImaginaryNetworkMotifs2024 | gvegayon/imaginary-structures | `0487d7d` (2023-09-18) | Release to create. Next commit is 2025 (package work) |
| ouellet2022 | gvegayon/use_of_force | `be42cad` (2021-12-04, HEAD, revision 1) | Release to create. Old tag `07apr2021` predates revision |
| Valente2019 | gvegayon/fctc | `9ef7494` (2019-01-22, HEAD) | Release to create. Existing `v0.1` (+ Zenodo) is the first submission |
| vegayonPowerMulticollinearitySmall2023a | gvegayon/jasa-comment-2023 | `95ac1e7` (2023-08-29, HEAD) | Release to create |
| yon2019exponential | muriteams/ergmito-simulations | `349fefe` (2020-05-05, last analysis commit) | Release to create. Manuscript source: muriteams/ergmito-paper `5623f8b` |
| najafzadehkhoeiMachineGeneralizeLearning2025a | UofUEpiBio/Calibrate_ABM | `66e1d29` (2025-07-31, before arXiv v1) or `6e62646` (2026-03-02, HEAD) | **Decide** which arXiv version to pin |
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
gh release create paper-ploscb-2021 --repo USCbiostats/aphylo-simulations \
  --target 348420d50a7d3d0474f023d81ea1c1d0c752852f \
  --title "Version used in Vega Yon et al. (2021), PLOS Computational Biology" \
  --notes "Code and data to reproduce https://doi.org/10.1371/journal.pcbi.1007948"

gh release create paper-socnet-2024 --repo gvegayon/imaginary-structures \
  --target 0487d7da555c76acf2db210041a1f8034baea209 \
  --title "Version used in Tanaka & Vega Yon (2024), Social Networks" \
  --notes "Code and data for https://doi.org/10.1016/j.socnet.2023.11.005"

gh release create paper-jqc-2022 --repo gvegayon/use_of_force \
  --target be42cadbd85bb118bce9127e0780b831fb7245a7 \
  --title "Version used in Ouellet et al. (2022), Journal of Quantitative Criminology" \
  --notes "Code for https://doi.org/10.1007/s10940-022-09546-9 (raw data not distributed)"

gh release create paper-ssm-2019 --repo gvegayon/fctc \
  --target 9ef7494b5bf0c3552bd83a3cb58a476b173e3eec \
  --title "Version used in Valente et al. (2019), Social Science & Medicine" \
  --notes "Code and data for https://doi.org/10.1016/j.socscimed.2019.01.008"

gh release create paper-jasa-2023 --repo gvegayon/jasa-comment-2023 \
  --target 95ac1e78de1984c02134f4aac0e8d512b5a11e1b \
  --title "Version used in Vega Yon (2023), JASA discussion" \
  --notes "Code for https://doi.org/10.1080/01621459.2023.2252041"

gh release create paper-socnet-2021 --repo muriteams/ergmito-simulations \
  --target 349fefefed32748c4a2597bc005aef62be69b549 \
  --title "Version used in Vega Yon et al. (2021), Social Networks" \
  --notes "Simulations for https://doi.org/10.1016/j.socnet.2020.07.005"

# Pick one target after checking which arXiv version you want pinned:
# 66e1d291e90469a3210405127b2b47bd0d4db567 (pre arXiv v1) or
# 6e62646bd7f8b306bc21651bda13a9c6881b7750 (current HEAD)
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
