# Eval report

Skill dir: eval/skills/text-to-loglog
Run dir: eval/skills/text-to-loglog/runs/20260911_1922_ph-v0.3.0

## Summary

* total_samples: 12
* scored_samples: 12
* pass: 12
* borderline: 0
* fail: 0
* avg_faithfulness_precision: 0.9959250000000001
* avg_must_recall: 0.9966666666666667
* avg_redundancy: 0.013900000000000001
* avg_weighted_score: 0.7939750000000001

## Per sample

| id | words | verdict | weighted | faithfulness | must_recall | redundancy |
| --- | --- | --- | --- | --- | --- | --- |
| 01_what_is_mathematics | 6618 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 02_case_for_transparent_government | 6741 | Pass | 0.798 | 1.0 | 1.0 | 0.0116 |
| 03_cant_stop_addicted_to_shindig | 5799 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 04_house_hunting_shenanigans | 3801 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 05_manufacturing_taste | 2918 | Pass | 0.79 | 0.9744 | 1.0 | 0.0 |
| 06_valuing_consistency | 2920 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 07_intentionalism | 2643 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 08_empathy_sympathy_compassion_matrix | 1321 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 09_not_even_wrong | 1345 | Pass | 0.78 | 1.0 | 0.96 | 0.0 |
| 10_parde_begardan_fa | 639 | Pass | 0.7814 | 0.9767 | 1.0 | 0.0465 |
| 11_finding_a_phone | 3120 | Pass | 0.7783 | 1.0 | 1.0 | 0.1087 |
| 12_lets_talk_privacy | 2803 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |

## Fix backlog

Collect fix_list entries from each judge_top.json, ordered by frequency.
Use trace.md files in each sample dir for judge reasoning audit.
