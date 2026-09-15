# Text to loglog eval: process, results, and skill lessons

First full evaluation of the `point-hierarchy` skill (version 0.2.0), run on 2026-09-11. This file records how the eval was built, what was measured, what the scores were, and what the skill must fix. It lives next to the raw audit trail so a future run can be compared against it.

## Corpus

12 blog posts frozen under `corpus/sources`, picked from the last 40 posts by filename date, filtered to over 200 words, stratified by type and length. Full selection metadata is in `corpus.json`.

| id | source | words | type |
| --- | --- | --- | --- |
| 01 | what_is_mathematics | 6618 | technical essay |
| 02 | case_for_transparent_government | 6741 | argumentative |
| 03 | cant_stop_addicted_to_shindig | 5799 | personal long |
| 04 | house_hunting_shenanigans | 3801 | narrative |
| 05 | manufacturing_taste | 2918 | essay |
| 06 | valuing_consistency | 2920 | essay |
| 07 | intentionalism | 2643 | argumentative |
| 08 | empathy_sympathy_compassion_matrix | 1321 | structured comparison |
| 09 | not_even_wrong | 1345 | critique, negation heavy |
| 10 | parde_begardan_fa | 639 | Farsi essay, experimental |
| 11 | finding_a_phone | 3120 | narrative plus process |
| 12 | lets_talk_privacy | 2803 | technical explainer |

## Judge architecture

No ground truth summaries exist, so the source text is the reference. Four judges score only the generated loglog outline (`output.log`). The graph and viewer were not scored.

* Judge F (faithfulness): atomizes the outline into atomic claims and verdicts each against the source as Supported, Partially supported, Unverifiable, or Contradicted. Any drift in a number, date, name, or negation polarity is Contradicted Critical. Spec in `prompts/judge_faithfulness.md`.
* Judge Cov (coverage): builds 8 to 15 key points from the source blind, weighted Must have or Nice to have, then maps each to Present, Partial, or Missing in the outline. Spec in `prompts/judge_coverage.md`.
* Judge Con (concision): labels claims Unique, Duplicate, Trivia, or Boilerplate and measures redundancy rate plus tokens per unique claim. Spec in `prompts/judge_concision.md`.
* Judge Top (overall): applies the gates and weights in `config.json` and returns Pass, Borderline, or Fail with shown math plus an ordered fix list. Spec in `prompts/judge_top.md`.

Pass gates: zero Critical errors, faithfulness precision at least 0.95, Must have recall at least 0.90, redundancy below 0.15. Concision never compensates for a faithfulness or coverage fail.

## How the run was executed

Run dir: `runs/20260911_1434_ph-v0.2.0`, created with `eval/run_eval.sh point-hierarchy ph-v0.2.0`.

1. Skill execution: four parallel workers ran the `point-hierarchy` extraction passes (Survey, Skeleton, Trace, Assembly, Deduplication) on batches of samples. Each graph was validated with `scripts/graph.py validate` until zero errors and zero uncited passages, then rendered with `to-outline`. The outline was copied to `<sample>/output.log` and the graph to `<sample>/graph.json`. All 12 graphs validated clean on the first pass, with only minor fidelity repairs (restored dropped passages, fixed citations).
2. Judging: four parallel workers ran Judges F, Cov, Con, then Top per sample, saving `judge_faithfulness.json`, `judge_coverage.json`, `judge_concision.json`, `judge_top.json` and appending full reasoning transcripts to `trace.md`.
3. Aggregation: `python3 eval/lib/aggregate.py` produced `report.md` plus `summary.json`. `python3 eval/lib/check.py` confirmed the full audit trail for all 12 samples.

## Results

6 Pass, 6 Borderline, 0 Fail. Averages: faithfulness precision 0.977, Must have recall 0.963, redundancy 0.007, weighted score 0.775. Zero Critical errors in all 12 samples.

| id | verdict | faithfulness | must recall | redundancy |
| --- | --- | --- | --- | --- |
| 01 | Borderline | 0.969 | 0.944 | 0.015 |
| 02 | Borderline | 0.951 | 0.917 | 0.012 |
| 03 | Borderline | 0.969 | 0.962 | 0.000 |
| 04 | Pass | 1.000 | 1.000 | 0.000 |
| 05 | Borderline | 0.981 | 1.000 | 0.000 |
| 06 | Borderline | 0.977 | 0.962 | 0.000 |
| 07 | Pass | 0.981 | 1.000 | 0.058 |
| 08 | Pass | 1.000 | 1.000 | 0.000 |
| 09 | Pass | 0.971 | 1.000 | 0.000 |
| 10 | Pass | 0.960 | 0.900 | 0.000 |
| 11 | Borderline | 0.969 | 0.955 | 0.000 |
| 12 | Pass | 1.000 | 0.917 | 0.000 |

Every Borderline is a Minor qualifier or scope issue touching a Must have point, never a fabrication. Sample 02 is the closest call at 0.9506 with the only Contradicted claim in the corpus (six vs seven decades).

## What the skill must improve

Five recurring failure modes, ordered by frequency and impact. Each maps to a concrete skill change, applied in `point-hierarchy` version 0.3.0.

1. Dropped hedges and conditionals. The most frequent fault. Examples: Often dropped in 06, tend to dropped in 09, the if mechanisms are right conditional dropped in 05, I think dropped in 10. Each one turned a Must have point Partial and flagged the sample Borderline. Fix: the skill now has an explicit precision checklist in the Fidelity check naming hedges and conditionals as mandatory survivors, plus a rule that a hedged source stated as absolute fact is a defect.
2. Narrowed number ranges and upgraded scoped figures. Examples: tens to thousands narrowed to hundreds in 01, 34 percent rounded to a third in 02, 38 strategies across 14 families collapsed to 38 families in 03, week long battery generalized from one model to a general requirement in 11. Fix: new non negotiable rule that ranges are never narrowed, scoped figures are never generalized, and counts keep both parts (38 strategies, 14 families).
3. Dropped Must have numbers. Examples: AES-256, 30 digit passphrase, and 64 char key missing in 12, 20k price and six months timing missing in 10. These are coverage misses on technical explainers, where numbers carry the meaning. Fix: the Trace pass now flags passages whose load bearing content is a number, and the Fidelity checklist requires every flagged number to appear in its node.
4. Dropped qualifiers on evidence. Examples: business NZ window and major breach record in 02, fake vs manufacture a sense of authenticity in 09. Fix: covered by the same precision checklist, with scope adjectives called out.
5. Minor duplication and trivia. Examples: repeated headers in 01, repeated evidence in 02, three safe merges in 07, one gloss and one transition line as trivia in 01 and 05. Low impact, redundancy averaged 0.007 against a 0.15 cap. Fix: Pass 4 already covers dedup, so no new rule, but the Render read now explicitly asks whether any outline branch restates an earlier branch.

What needs no change: attribution handling was clean across counterpoints and reported positions, narrative texts correctly used theme nodes, the Farsi sample passed at the same bar, and no negation polarity was flipped anywhere.

## Rerun with skill v0.3.0

Rerun on 2026-09-12 after the precision fixes, same corpus, same prompts, same gates. Run dir: `runs/20260911_1922_ph-v0.3.0`.

Result: 12 Pass, 0 Borderline, 0 Fail. Averages: faithfulness precision 0.996 (up 0.019), Must have recall 0.997 (up 0.034), redundancy 0.014 (up 0.007, still far below the 0.15 cap), weighted score 0.794 (up 0.019). Every v0.2.0 Borderline moved to Pass. The two longest texts grew in node count under the stricter Fidelity sweep (01 from 65 to 129 nodes, 02 from 81 to 250) and both reached 1.0 faithfulness with full Must recall.

Residual faults for the next iteration, all Minor: one rounded count in 05 (over 3,400 stated as flat 3,400), one dropped qualifier in 09 (credible sources in relevant domains), one retained hedge gap in the Farsi header of 10 (kept in the sub point, dropped in the header), and header detail duplication in 11 (redundancy 0.109, the highest in the corpus but still inside the gate). The pattern to attack next is rounding of approximate counts and header level compression, which is where the remaining Partials cluster.

Per sample movement, v0.2.0 to v0.3.0:

| id | verdict | faithfulness | weighted |
| --- | --- | --- | --- |
| 01 | Borderline to Pass | 0.969 to 1.000 | 0.762 to 0.800 |
| 02 | Borderline to Pass | 0.951 to 1.000 | 0.745 to 0.798 |
| 03 | Borderline to Pass | 0.969 to 1.000 | 0.772 to 0.800 |
| 04 | Pass to Pass | 1.000 to 1.000 | 0.800 to 0.800 |
| 05 | Borderline to Pass | 0.981 to 0.974 | 0.792 to 0.790 |
| 06 | Borderline to Pass | 0.977 to 1.000 | 0.775 to 0.800 |
| 07 | Pass to Pass | 0.981 to 1.000 | 0.781 to 0.800 |
| 08 | Pass to Pass | 1.000 to 1.000 | 0.800 to 0.800 |
| 09 | Pass to Pass | 0.971 to 1.000 | 0.788 to 0.780 |
| 10 | Pass to Pass | 0.960 to 0.977 | 0.744 to 0.781 |
| 11 | Borderline to Pass | 0.969 to 1.000 | 0.769 to 0.778 |
| 12 | Pass to Pass | 1.000 to 1.000 | 0.767 to 0.800 |

## Rerunning

To score a new skill version against the same corpus, create a fresh run and repeat the three steps. Keep prompts and gates pinned so versions are comparable.

```bash
./eval/run_eval.sh point-hierarchy <label>
python3 eval/lib/aggregate.py eval/skills/point-hierarchy eval/skills/point-hierarchy/runs/<stamp>_<label>
python3 eval/lib/check.py eval/skills/point-hierarchy eval/skills/point-hierarchy/runs/<stamp>_<label>
```
