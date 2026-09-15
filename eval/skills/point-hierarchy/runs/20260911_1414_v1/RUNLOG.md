# Run 20260911_1414 v1

Skill: point-hierarchy
Created: 20260911_1414
Config snapshot: config.snapshot.json

Workflow per sample dir:
source.txt plus output.log plus 4 judge JSON files plus trace.md

Finish with:
python3 eval/lib/aggregate.py eval/skills/point-hierarchy /home/k1/public/claude_public_skills/eval/skills/point-hierarchy/runs/20260911_1414_v1
python3 eval/lib/check.py eval/skills/point-hierarchy /home/k1/public/claude_public_skills/eval/skills/point-hierarchy/runs/20260911_1414_v1
