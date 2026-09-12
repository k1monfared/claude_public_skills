# Eval report

Skill dir: eval/skills/text-to-loglog
Run dir: eval/skills/text-to-loglog/runs/20260911_1434_ph-v0.2.0

## Summary

* total_samples: 12
* scored_samples: 12
* pass: 6
* borderline: 6
* fail: 0
* avg_faithfulness_precision: 0.9771875
* avg_must_recall: 0.9629416666666667
* avg_redundancy: 0.007116666666666667
* avg_weighted_score: 0.7746333333333334

## Per sample

| id | words | verdict | weighted | faithfulness | must_recall | redundancy |
| --- | --- | --- | --- | --- | --- | --- |
| 01_what_is_mathematics | 6618 | Borderline | 0.7624 | 0.9692 | 0.9444 | 0.0154 |
| 02_case_for_transparent_government | 6741 | Borderline | 0.7445 | 0.9506 | 0.9167 | 0.0123 |
| 03_cant_stop_addicted_to_shindig | 5799 | Borderline | 0.7721 | 0.9688 | 0.9615 | 0.0 |
| 04_house_hunting_shenanigans | 3801 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 05_manufacturing_taste | 2918 | Borderline | 0.7923 | 0.9808 | 1.0 | 0.0 |
| 06_valuing_consistency | 2920 | Borderline | 0.7753 | 0.9767 | 0.9615 | 0.0 |
| 07_intentionalism | 2643 | Pass | 0.7808 | 0.9808 | 1.0 | 0.0577 |
| 08_empathy_sympathy_compassion_matrix | 1321 | Pass | 0.8 | 1.0 | 1.0 | 0.0 |
| 09_not_even_wrong | 1345 | Pass | 0.7882 | 0.9706 | 1.0 | 0.0 |
| 10_parde_begardan_fa | 639 | Pass | 0.744 | 0.96 | 0.9 | 0.0 |
| 11_finding_a_phone | 3120 | Borderline | 0.7693 | 0.96875 | 0.9545 | 0.0 |
| 12_lets_talk_privacy | 2803 | Pass | 0.7667 | 1.0 | 0.9167 | 0.0 |

## Fix backlog

Collect fix_list entries from each judge_top.json, ordered by frequency.
Use trace.md files in each sample dir for judge reasoning audit.
