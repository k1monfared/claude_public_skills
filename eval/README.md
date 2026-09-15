# Eval harness, multi skill

One harness scores many skills. Each skill owns its corpus, prompts, config, and runs. Shared code lives in `eval/lib`.

## Layout

```text
eval/
  README.md
  run_eval.sh
  lib/
    aggregate.py
    check.py
  skills/
    point-hierarchy/
      config.json
      corpus.json
      prompts/
        judge_faithfulness.md
        judge_coverage.md
        judge_concision.md
        judge_top.md
      corpus/sources/
      runs/YYYYMMDD_HHMM_label/
        config.snapshot.json
        RUNLOG.md
        report.md
        summary.json
        <sample-id>/
          source.txt
          output.log
          judge_faithfulness.json
          judge_coverage.json
          judge_concision.json
          judge_top.json
          trace.md
```

## Add a new skill eval

1. Copy `skills/point-hierarchy` to `skills/<new-skill>` as a layout reference.
2. Replace `corpus.json`, `corpus/sources`, `config.json`, and files in `prompts`.
3. Keep the same per sample file names so `aggregate.py` and `check.py` work unchanged.
4. Create a run with `./run_eval.sh <new-skill> v1`.

## Run workflow

```bash
./eval/run_eval.sh point-hierarchy v1
# fill output.log per sample with the skill under test
# run the 4 judge prompts, save JSON outputs per sample
# append full judge transcripts to trace.md per sample
python3 eval/lib/aggregate.py eval/skills/point-hierarchy eval/skills/point-hierarchy/runs/<stamp>_v1
python3 eval/lib/check.py eval/skills/point-hierarchy eval/skills/point-hierarchy/runs/<stamp>_v1
```

## Audit rule

Every verdict must trace to evidence. Judge JSON files hold scores. `trace.md` holds full reasoning transcripts. `config.snapshot.json` pins weights per run. Use the fix_list fields in `judge_top.json` files as the backlog for skill improvement.
