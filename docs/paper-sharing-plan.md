# Plan: releasing my papers on ggvy.cl, ResearchGate, and preprint servers

**Status:** draft for review · **Compiled:** 2026-09-05 · **Source of record for the paper list:** `papers.toml`

The goal is to make a downloadable copy of every manuscript available to
readers, without breaking a publishing agreement. Publisher rules are not
uniform, so this plan works paper by paper: what may be posted, in which
version, and where.

Everything below is a good-faith reading of the publishers' public policies as
of September 2026. It is not legal advice, and a signed author agreement always
wins over a public policy page. Section 7 lists the checks to run before the
first upload.

---

## 1. The three versions of a paper

Almost every rule in this document turns on which file is being posted. Naming
them the way publishers do avoids most mistakes.

| Version | What it is | Rule of thumb |
|---|---|---|
| **Preprint / submitted version** | What was submitted, before peer review | Mine to post nearly anywhere, nearly always |
| **AAM** — accepted (author) manuscript | Post-peer-review, pre-copyedit; my own typesetting, no journal logo or page numbers | The workhorse of this plan |
| **VoR** — version of record | The publisher's typeset PDF | Only postable when the article is open access under a Creative Commons licence |

**Practical consequence:** the AAM is what gets posted for every subscription
paper. That means keeping (or reconstructing) the accepted LaTeX/Word source
for each one. Where the accepted source is lost, the fallback is a link to the
DOI plus a link to PubMed Central where a deposit exists.

## 2. The four destinations, ranked by how permissive they are

1. **ggvy.cl (my own non-commercial personal website).** The most permissive
   destination by a wide margin. Elsevier, Sage, Oxford University Press and
   Taylor & Francis all allow the AAM here **immediately**, with no embargo.
   Springer Nature is the exception — it applies its embargo to personal sites
   too.
2. **arXiv / medRxiv / bioRxiv / RePEc.** Fully mine for preprints. Elsevier
   additionally allows the *accepted* manuscript to replace an existing arXiv or
   RePEc preprint immediately, with a CC BY-NC-ND licence and a DOI link.
3. **University of Utah institutional repository (Hive) and PubMed Central.**
   Subject to the journal's embargo, except where a funder mandate overrides it
   (Section 6).
4. **ResearchGate.** The most restricted. It is a *commercial* platform, so most
   publishers' "non-commercial repository" permissions do not extend to it.
   Taylor & Francis names ResearchGate explicitly and allows the AAM there after
   the embargo; Elsevier, Sage, Springer Nature and OUP do not. For those, the
   safe pattern is **metadata + DOI link only** (ResearchGate's "request
   full-text" button is fine — private, one-to-one sharing is permitted by all
   of these publishers).

Open-access articles under CC BY (or CC BY-NC-ND) are exempt from all of this:
the publisher's own PDF may be posted anywhere, including ResearchGate, as long
as attribution and the licence notice ride along.

## 3. Per-paper determination

Dates are the ones in `papers.toml`; embargo clocks run from first online
publication, which for several of these is earlier than the issue date. "Clear"
means the embargo has expired as of September 2026.

### 3.1 Fully open access — post the publisher PDF anywhere

No embargo, no AAM needed, ResearchGate included. Keep the licence line and the
DOI on the copy.

| Paper | Venue | Licence |
|---|---|---|
| `vegayon2020aphylo` — Bayesian parameter estimation … gene functions | PLOS Computational Biology (2021) | CC BY 4.0 |
| `VegaYon2019a` — fmcmc | JOSS (2019) | CC BY 4.0 |
| `VegaYon2019b` — slurmR | JOSS (2019) | CC BY 4.0 |
| `VegaYon2021rgexf` — rgexf | JOSS (2021) | CC BY 4.0 |
| `meyerEpiworldRFastAgentBased2023` — epiworldR | JOSS (2023) | CC BY 4.0 |
| `Hancean2022` — Formation of political discussion networks | Royal Society Open Science (2022) | CC BY 4.0 (fully gold OA journal) |
| `duongIncorporatingSocialDeterminants2024` — SDOH in COVID-19 vaccine modelling | Lancet Regional Health – Americas (2024) | Gold OA; confirm CC BY vs CC BY-NC-ND on the article page |
| `mohammadiNovelApproachClassifying2025c` — Classifying monoamine neurotransmitters | Nanoscale Advances, RSC (2025) | Fully gold OA; confirm CC BY vs CC BY-NC |
| `visnovskyMultidrugResistantOrganism2026` — MDRO-contaminated mobile equipment (P-1104) | Open Forum Infectious Diseases suppl. (2026) | OUP fully OA; confirm the supplement's licence |
| `milandoVisionEstimationInstantaneous2026` — Vision for estimation of R_t | Epidemics (2026) | Epidemics runs an OA model — **verify the licence on this specific article** before treating it as CC BY |
| `FabregaLacoa2013` — Rating televisivo y Twitter | Cuadernos.info (2013) | Latin American diamond-OA journal, Creative Commons; confirm the exact variant |

### 3.2 Subscription, embargo already expired — AAM everywhere except ResearchGate

For each of these: post the AAM on ggvy.cl, deposit in Hive, and link the DOI.
ResearchGate gets link-only unless noted.

| Paper | Venue / publisher | First online | Embargo | Where the AAM may go now |
|---|---|---|---|---|
| `yon2019exponential` — ERGMs for little networks | Social Networks / Elsevier | Aug 2020 | 24 mo — clear | ggvy.cl, Hive, arXiv/RePEc update. **Not** ResearchGate |
| `tanakaImaginaryNetworkMotifs2024` — Imaginary network motifs | Social Networks / Elsevier | Dec 2023 | 24 mo — clear | Same |
| `sargentAssessingDynamicsPrEP2024` — PrEP adoption in a physician network | Social Networks / Elsevier | Feb 2024 | 24 mo — clear | Same |
| `Valente2019` — Network influences on policy implementation | Social Science & Medicine / Elsevier | 2019 | 36 mo (journal-specific; verify) — clear | Same; also check for a PMC deposit |
| `panahiVeteranPerspectivesEpilepsy2023` — Veteran perspectives of epilepsy care | Epilepsy & Behavior / Elsevier | Jul 2023 | 12 mo — clear | Same; VA-funded, check PMC |
| `ouellet2022` — Officer networks and firearm behaviors | J. Quantitative Criminology / Springer | Jun 2022 | 12 mo — clear | ggvy.cl, Hive. Springer's AAM terms of use apply: no CC licence, no reformatting. **Not** ResearchGate |
| `Bell2019` — Sensing eating mimicry among family members | Translational Behavioral Medicine / OUP | May 2019 | Personal site immediate; repositories 12 mo — clear | ggvy.cl, Hive. **Not** ResearchGate (OUP excludes commercial sites) |
| `vegayonPowerMulticollinearitySmall2023a` — Power and multicollinearity (JASA discussion) | JASA / Taylor & Francis | Oct 2023 | 12–18 mo — clear | ggvy.cl, Hive, **and ResearchGate** — T&F permits SCNs post-embargo |
| `DelaHaye2019` — Smoking diffusion through adolescent networks | J. Health and Social Behavior / Sage | 2019 | Sage green OA: no embargo on the AAM | ggvy.cl, Hive. ResearchGate: link-only |
| `Valente2020` — Diffusion/contagion processes on social networks | Health Education & Behavior / Sage | 2020 | No embargo on the AAM | Same |
| `piombo2025` — Social norms and e-cigarette diffusion | Health Education & Behavior / Sage | Mar 2025 | No embargo on the AAM | Same; if NIH-funded and accepted on/after 2025-07-01, the AAM belongs in PMC with zero embargo (Section 6) |

### 3.3 Subscription, still embargoed

| Paper | Venue | Situation | What to do now |
|---|---|---|---|
| `vegayon-ltcf` — ERGMs in resident-HCP networks (in press) | Social Networks / Elsevier | Elsevier's 24-month embargo runs to roughly 2028 from the online date | Three things are still allowed immediately: (a) the AAM on **ggvy.cl**, licensed CC BY-NC-ND with a DOI link; (b) updating an existing arXiv/RePEc preprint with the AAM under the same terms; (c) a **funder mandate override** — if this is NIH- or VA-funded and accepted on/after 2025-07-01, deposit the AAM in PMC for immediate public release, which also gives a clean public link to use everywhere else. **Not** ResearchGate, and **not** Hive until the embargo lapses (unless a funder mandate applies) |

### 3.4 Special case — the Stata Journal

| Paper | Venue | Situation |
|---|---|---|
| `VegaYon2019c` — `parallel`: a command for parallel computing | The Stata Journal (StataCorp / Sage), Sep 2019 | Copyright is **assigned to StataCorp** under the Contributor Assignment Agreement, and StataCorp's terms of use forbid placing electronic copies on publicly accessible sites without written permission. However, Stata Journal articles older than three years are free to read on stata-journal.com — this one has been since late 2022. |

**Recommendation:** do not upload a PDF. Link to the free full text at
stata-journal.com. If a hosted copy matters, email StataCorp for written
permission first — this is the one paper in the set where posting without
asking would be a clear breach.

### 3.5 Preprints and working papers — mine to post

Copyright is retained in all of these, so they can go on ggvy.cl and
ResearchGate. Two cautions: honour whatever licence was selected when posting
to medRxiv/arXiv, and re-check any item that later gets accepted somewhere,
because the accepted version then falls under Section 3.2/3.3 rules.

| Paper | Server / status |
|---|---|
| `vegayonDiscreteExponentialFamilyModels2022` — Discrete exponential-family models | arXiv 2211.00627 |
| `najafzadehkhoeiMachineGeneralizeLearning2025a` — Generalized ML for calibrating ABMs | arXiv 2509.07013 |
| `loveCharacterizingSpatiotemporalVariation2023` — Mpox transmission heterogeneity | medRxiv 2023.05.10.23289580 |
| `maryeHiddenBurdenMeasles2026` — Hidden burden of a measles outbreak | medRxiv |
| `johnsonBayesianGenerativeModeling2026` — Bayesian modelling of wastewater data | medRxiv |
| `lesslerWhyEpidemicRisk2026` — Epidemic risk at the 2026 World Cup | medRxiv |
| `vegayonPracticalGuidelinesReflections2026` — Building public health software | JMIR preprint; the published version will be gold OA CC BY |
| `vegayon-geese` — Modeling gene functional evolution | Unpublished; consider posting to bioRxiv/arXiv to make it citable |

### 3.6 Commissioned technical reports (Chile)

| Paper | Note |
|---|---|
| `quintanilla2013estudio` — Estudio actuarial, Seguro de Cesantía | Likely commissioned work; copyright probably sits with the commissioning body, not with me. Confirm before hosting a PDF |
| `repetto2013impacto` — Alza en la cotización previsional (CPL, UAI) | Same question for UAI's Centro de Políticas Laborales |
| `RePEc:sdp:sdpwps:57` — Capital Necesario Unitario (CNU) | Already a public working paper on RePEc; link, and host a copy once the rights question above is settled |

**Action:** one email each to the Superintendencia de Pensiones and to CPL/UAI
asking whether a PDF may be hosted on a personal academic site. Until they
answer, link to the existing public copies.

## 4. Publisher rulebook

The per-publisher detail behind Section 3, for when a new paper needs to be
classified.

### Elsevier — Social Networks, Social Science & Medicine, Epilepsy & Behavior, Epidemics, Lancet Regional Health

- **VoR:** never posted publicly unless the article is gold/hybrid OA under a
  Creative Commons licence. Explicitly not on ResearchGate or Academia.edu.
- **AAM on a non-commercial personal website or blog:** allowed **immediately**,
  no embargo. Must carry a CC BY-NC-ND licence and a link to the formal
  publication.
- **AAM in institutional/non-commercial repositories:** after the
  journal-specific embargo. Social Networks 24 months, Epilepsy & Behavior 12
  months, Social Science & Medicine 36 months (all to be re-checked against
  Elsevier's Journal Embargo Finder, which is the authoritative source).
- **arXiv / RePEc:** an existing preprint may be updated with the AAM
  immediately, CC BY-NC-ND plus DOI link. bioRxiv and medRxiv are not named in
  the policy — treat them as unresolved rather than as permitted.
- **ResearchGate:** not permitted for the AAM (commercial platform). Link only.

### Sage — Journal of Health and Social Behavior, Health Education & Behavior, The Stata Journal

- **AAM:** may be posted on a personal website, a departmental website, or an
  institutional repository **with no embargo** — Sage removed its 12-month green
  embargo. Older documentation still shows 12 months; the current author
  archiving guidelines govern.
- **VoR:** only if the article was published OA.
- **ResearchGate:** Sage does not extend the repository permission to commercial
  SCNs. Link only.
- The Stata Journal sits under a separate StataCorp agreement — see §3.4.

### Springer Nature — Journal of Quantitative Criminology

- **AAM:** personal website and funder/institutional repositories after the
  journal's embargo (12 months for most Springer journals). Unlike Elsevier and
  OUP, the embargo applies to the personal site too.
- The AAM must be posted under Springer Nature's **AAM Terms of Use** — it may
  not be relicensed under Creative Commons, reformatted, or enhanced.
- **ResearchGate:** Springer Nature has a "Journal Home" partnership with
  ResearchGate, but that is publisher-driven syndication, not author upload. It
  is not a permission to post my own copy.

### Oxford University Press — Translational Behavioral Medicine, Open Forum Infectious Diseases

- **AAM on my own personal webpage:** immediately, no embargo. OUP explicitly
  excludes commercial websites and repositories from this permission.
- **AAM in institutional/subject repositories:** deposit immediately, public
  release after the journal embargo (12 months typically; per-journal table on
  Oxford Academic).
- OFID is fully open access — §3.1 applies to it instead.

### Taylor & Francis — JASA

- **AAM on a personal or departmental website:** immediately.
- **AAM in a repository or on an SCN such as ResearchGate:** after the embargo —
  12 months for STM titles, 18 for social sciences and humanities. Either way,
  the 2023 JASA discussion is clear.
- **VoR:** only if published OA.

### PLOS, JOSS, Royal Society Open Science, RSC, Lancet OA titles, JMIR

Fully open access under Creative Commons. The publisher PDF goes anywhere,
attribution intact.

## 5. Implementation on ggvy.cl

The site already has most of the machinery. `R/detail.R:155` renders a **PDF**
link from a `pdf` field on a paper entry, and `_quarto.yml` copies `assets/`
verbatim into `public/`. So:

1. **Create `assets/papers/`** and drop the files there. `assets/` is already in
   the `resources:` list, so no config change is needed; a top-level `pdf/`
   directory would need adding to that list, which is why `assets/papers/` is
   the better home.
2. **Naming:** `<bibkey>-<version>.pdf`, e.g.
   `tanakaImaginaryNetworkMotifs2024-aam.pdf`,
   `vegayon2020aphylo-vor.pdf`. The version suffix keeps the audit trail
   visible in the filesystem, which matters when a compliance question comes up
   two years later.
3. **Add the field** to each entry in `papers.toml`:
   `pdf = '/assets/papers/<file>.pdf'`.
4. **Surface PDF links on the cards, not only the detail pages.** `R/cards.R`
   (around line 172) and `R/research_publications.R` (around line 134) build
   their link rows from `doi`, `url` and `eprint` only. Adding the `pdf` field
   there — mirroring `R/detail.R:149-160` — is a small, contained change and is
   what makes the download actually discoverable.
5. **Stamp every AAM** with a cover line before uploading. For Elsevier titles
   this is a requirement, not a nicety:

   > Accepted manuscript. Published as: <full citation>. <DOI URL>.
   > © <year>. This manuscript version is made available under the
   > CC BY-NC-ND 4.0 licence: https://creativecommons.org/licenses/by-nc-nd/4.0/

   For Springer AAMs, replace the CC line with a pointer to Springer Nature's
   AAM Terms of Use — a CC licence on a Springer AAM would itself be a breach.
6. **Add a `rights`/`license` field** to `papers.toml` recording the
   determination for each paper (e.g. `sharing = 'vor-ccby'`, `'aam-only'`,
   `'link-only'`). This is what keeps the plan from decaying: the decision lives
   next to the paper instead of in this document.
7. **Optional:** a short "Sharing and reuse" note on `research.qmd` explaining
   that AAMs are posted where the publisher permits and that the DOI link is
   the version of record. It costs one paragraph and answers the question
   before anyone asks it.

## 6. Funder mandates — the override that often beats the embargo

- **NIH (2024 Public Access Policy, effective 2025-07-01).** For any
  NIH-supported manuscript **accepted on or after 1 July 2025**, the AAM must go
  to PubMed Central and be public **immediately on the publication date, with no
  embargo**. Publisher embargoes do not apply. This is directly relevant to
  `piombo2025`, `vegayon-ltcf`, `milandoVisionEstimationInstantaneous2026`, and
  anything else NIH-funded now in the pipeline: the PMC copy becomes a stable,
  freely linkable version well before the publisher would allow one.
- **Older NIH-funded papers** (`Bell2019`, `DelaHaye2019`, `Valente2019`,
  possibly others) should already have PMC deposits under the previous
  12-month policy. Worth an audit — where a PMC record exists, linking it is
  simpler and safer than hosting a copy.
- **VA-funded work** (`panahiVeteranPerspectivesEpilepsy2023`, `vegayon-ltcf`)
  carries its own public-access requirements. Confirm with the VA program
  officer which deposit route applies.
- **Federal agencies generally** were directed to drop embargoes for federally
  funded research by the end of 2025. Check the specific award terms for each
  paper rather than assuming a uniform rule.

## 7. Execution order

**Step 1 — verify before uploading anything** (a couple of hours' work):
  - Run every DOI through **Sherpa Romeo** (`v2.sherpa.ac.uk/romeo/`) and
    Elsevier's **Journal Embargo Finder** to confirm the embargo numbers in
    §3.2. The two Elsevier figures worth double-checking are Social Science &
    Medicine (36 months) and Social Networks (24 months).
  - Open each §3.1 article page and record the **exact licence string**. The
    four to confirm are Epidemics, Lancet Regional Health – Americas, Nanoscale
    Advances, and the OFID supplement.
  - Check **PubMed Central** for existing deposits.
  - Skim the signed author agreements for anything that contradicts a public
    policy page — the agreement is what governs.

**Step 2 — the easy wins.** Post the 11 open-access PDFs from §3.1 to ggvy.cl
and ResearchGate. No embargo analysis, no AAM reconstruction, no risk.

**Step 3 — the AAMs.** Reconstruct or locate the accepted source for the 11
papers in §3.2, apply the §5.5 cover stamp, and post to ggvy.cl. Then deposit
in Hive and update ResearchGate — full text only for the JASA discussion,
link-only for the rest.

**Step 4 — the in-press LTCF paper.** Post the AAM on ggvy.cl immediately under
CC BY-NC-ND, and settle the funder-mandate question, which may make a PMC copy
available years ahead of the Elsevier embargo.

**Step 5 — the two email threads.** StataCorp (Stata Journal hosting) and the
Chilean commissioning bodies (technical reports).

**Step 6 — record the decisions** in `papers.toml` per §5.6 so future papers get
classified as they are added rather than re-litigated in bulk.

## 8. For future papers

- **Preprint first, every time.** A preprint posted before submission is
  unambiguously mine to share, forever, and removes the entire embargo question
  for the version most readers will actually download.
- **Consider the cOAlition S Rights Retention Strategy:** add to the submission
  a statement that the AAM is licensed CC BY, applied prior to acceptance. It
  is what makes zero-embargo sharing lawful regardless of what the publishing
  agreement later says.
- **Read the licence-to-publish before signing.** Exclusive transfer of
  copyright is usually negotiable, and a licence-to-publish keeps ownership.
- **Prefer OA venues where the work fits.** Ten of these papers are already in
  fully OA journals, and those are precisely the ones with no plan needed.

---

### Sources

- [Journals article sharing | Elsevier policy](https://www.elsevier.com/about/policies-and-standards/sharing)
- [Article sharing and hosting FAQs | Elsevier policy](https://www.elsevier.com/about/policies-and-standards/sharing/policy-faq)
- [Hosting articles | Elsevier policy](https://www.elsevier.com/about/policies-and-standards/hosting)
- [Journal embargo finder | Elsevier](https://elsevier.com/en-au/about/open-science/open-access/journal-embargo-finder)
- [Journal Specific Embargo Periods (Elsevier list, PDF)](https://legacyfileshare.elsevier.com/promis_misc/external-embargo-list.pdf)
- [Open access information — Social Networks | Elsevier](https://elsevier.com/journals/social-networks/0378-8733/open-access-options)
- [Open access information — Epilepsy & Behavior | Elsevier](https://www.elsevier.com/journals/epilepsy-and-behavior/1525-5050/open-access-options)
- [Open access information — Epidemics | Elsevier](https://www.elsevier.com/journals/epidemics/1755-4365/open-access-journal)
- [Sage's author archiving and re-use guidelines](https://www.sagepub.com/journals/permissions/sages-author-archiving-and-re-use-guidelines)
- [Green Open Access gets greener with Sage and Emerald's "no embargo" policies — Cardiff University](https://blogs.cardiff.ac.uk/openaccess/green-open-access-gets-greener-with-sage-and-emeralds-no-embargo-policies/)
- [Self-archiving and manuscript deposition — Springer Nature](https://www.springernature.com/gp/new-content-item/23218974)
- [Self-archiving | Springer Nature Support](https://support.springernature.com/en/support/solutions/articles/6000257341-self-archiving)
- [Author self-archiving policy — Oxford Academic](https://academic.oup.com/pages/self_archiving_policy_b)
- [Accepted manuscript embargo periods — Oxford Academic](https://academic.oup.com/pages/open-research/open-access/charges-licences-and-self-archiving/accepted-manuscript-embargo-periods)
- [Sharing versions of journal articles — Taylor & Francis Author Services](https://authorservices.taylorandfrancis.com/research-impact/sharing-versions-of-journal-articles/)
- [ResearchGate and Taylor & Francis expand Journal Home partnership](https://newsroom.taylorandfrancisgroup.com/researchgate-and-taylor-and-francis-expand-journal-home-partnership/)
- [ResearchGate | Journal Home](https://www.researchgate.net/journal-home)
- [Terms and conditions of use — The Stata Journal](https://www.stata-journal.com/terms-of-use/)
- [FAQ — The Stata Journal](https://www.stata-journal.com/faq/)
- [Submissions — The Stata Journal](https://www.stata-journal.com/submissions/)
- [NIH Public Access Policy Overview | NIH Grants & Funding](https://grants.nih.gov/policy-and-compliance/policy-topics/public-access/nih-public-access-policy-overview)
- [Guidance on the Revised NIH Public Access Policy, Effective July 2025 — University of California OSC](https://osc.universityofcalifornia.edu/scholarly-publishing/policies-legislation/nih-public-access-2025/)
- [NIH's Revised Public Access Policy is Effective July 1, 2025 — UCSF Library](https://www.library.ucsf.edu/news/nihs-revised-public-access-policy-is-effective-july-1-2025/)
