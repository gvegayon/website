# Sourcing coauthor/mentee photos

This is the workflow for adding a `photo` to someone in `../../people.toml`.
It exists to keep two things true: every photo on the site plausibly depicts
the person it is attached to, and nothing is published without George looking
at it first.

**Hard rules, no exceptions:**

- Never bypass a login wall, CAPTCHA, or anti-bot measure to get a photo.
  **LinkedIn is a link target, never a photo source** -- its photos sit
  behind all three. If LinkedIn is the only lead, ask George to download it
  himself, or ask the person directly for a headshot.
- Nothing is copied into `../../img/people/`, added to `../../people.toml`,
  or recorded in `../../img/people/MANIFEST.toml` until George has approved
  that specific photo via `review.html` (step 4 below). A high confidence
  score is not approval.
- Prefer a photo the subject published of themselves (their own site,
  GitHub, an official directory entry). Never stock/agency/watermarked
  images. Record a one-line license/usage note per photo regardless.

## 1. Source ladder

Try in order; stop at a HIGH-confidence candidate, but grab a second,
independent source when it's cheap (it upgrades a MEDIUM to HIGH via S4
below).

1. **University faculty/staff directory** -- strongest evidence class. For
   University of Utah people, `medicine.utah.edu` profiles work;
   `profiles.faculty.utah.edu` pages can be empty shells. Also check
   department sites and `netsci.utah.edu`. For external academics, their own
   university's profile page.
2. **Personal or lab website** -- start from the `url` already in
   people.toml.
3. **GitHub avatar** -- `https://github.com/<user>.png?size=480`. Good for
   software coauthors: look for the handle in a package's `repo` field,
   its `DESCRIPTION`/`Authors@R`, or its contributor list. Skip identicons
   (geometric block patterns = no real photo).
4. **ORCID** -- rarely has a photo, but top-tier evidence when it does.
5. **Google Scholar profile** -- photo + name + affiliation + coauthor list
   on one page; overlap with papers.toml authors is strong S2 evidence.
6. **Conference bios / department news** -- dated pages naming the person
   with their role.
7. **Bluesky** -- public API, no login:
   `https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=<handle>`.
   Only when the handle is verifiably theirs (linked from their own site).
   Twitter/X is effectively login-walled now -- skip it.

## 2. Score each candidate (fill into `candidates.toml`)

For every candidate photo, record six yes/no signals plus a one-line
evidence note for each, in `candidates.toml`:

```toml
[[candidate]]
slug       = 'meyer'                 # matches the people.toml key
file       = 'candidates/meyer-1.jpg'
crop       = 'candidates/meyer-1-avatar.jpg'   # after make_avatar.sh
source_url = 'https://...'
page_title = 'Derek Meyer | DCC Staff'
retrieved  = 2026-08-30
s1 = true   # name match -- quote/paraphrase the evidence in `notes`
s2 = true   # affiliation/role match
s3 = true   # institutionally controlled page (false for personal/GitHub/Scholar)
s4 = false  # same face on >=2 independent sources -- compare visually
s5 = true   # no confusable same-named person in the same field/institution
s6 = true   # recent, clear, single-person headshot
confidence = 'high'   # see formula below
notes      = "U of U DCC staff directory lists 'Derek Meyer, Biostatistician'; matches people.toml affiliation."
```

Signal definitions:

- **S1 Name match** -- the source page states the full name matching
  people.toml's `name`/`aka` (surname + first name must match; middle
  initials may differ).
- **S2 Affiliation/role match** -- the page states an affiliation/role
  consistent with people.toml, or with the papers/software they coauthor.
- **S3 Institutional page** -- university/employer/official-lab domain.
  Personal sites, GitHub, and Scholar are self-controlled, not
  institutional -> `false` here (they earn weight via S1/S2/S4 instead).
  Aggregators/scrapes (e.g. ResearchGate mirrors) are `false` here **and**
  don't count as an independent source for S4.
- **S4 Cross-source facial consistency** -- *visually compare* the images:
  the same face appears on >=2 independent domains, each satisfying S1. Two
  pages syndicating the same original file count as one source.
- **S5 Name-collision check** -- search `"<full name>" <affiliation-or-field>`
  and confirm no different, confusable same-named person turns up in the same
  field. If same-named academics exist, S2 must match the *exact*
  institution. **`false` here forces LOW, no matter what else is true.**
- **S6 Recency & quality** -- the photo/profile looks current (roughly
  within the last ~8 years) and is a clear, single-person headshot. A face
  cropped out of a group photo: note it, and cap at MEDIUM regardless of the
  other signals.

Confidence, computed mechanically:

- **HIGH** = s5 AND s6 AND ( (s1 AND s2 AND s3) OR (s1 AND s4) )
- **MEDIUM** = s5 AND s1 on a single self-controlled source (personal site;
  or a GitHub avatar whose handle is linked from the person's own
  site/ORCID/paper -- a second independent face match upgrades this to HIGH)
- **LOW** = anything else, any S5 failure, or any facial *mismatch* between
  sources. **Never approve a LOW candidate** -- list it as "no acceptable
  candidate, ask them directly" instead.

## 3. Crop

```sh
./make_avatar.sh candidates/meyer-1.jpg candidates/meyer-1-avatar.jpg
```

`candidates/` is gitignored -- it's scratch space, not part of the repo.

## 4. Generate and act on the review page

```sh
Rscript review.R
open review.html
```

Send George `review.html` (or the rendered candidates) and wait for his
per-photo approval. Only for the slugs he approves:

1. `cp candidates/<slug>-avatar.jpg ../../img/people/<slug>.jpg`
2. Add `photo = 'img/people/<slug>.jpg'` under that person's table in
   `../../people.toml`.
3. Add the matching table to `../../img/people/MANIFEST.toml` (see the
   `[gvy]` entry there for the shape): `file`, `source_url`, `retrieved`,
   `evidence`, `confidence`, `license`, `approved` (today's date).

Rejected or LOW-confidence people are left untouched -- they keep rendering
exactly as they do today, with no photo.
