#!/bin/bash
# Claude Code hook: records which skill is running, for the Jezero Content Base page.
# Reads the hook JSON on stdin and writes status.js next to index.html.
#
# Wire it up in ~/.claude/settings.json:
#   "hooks": {
#     "PreToolUse":  [{ "matcher": "Skill", "command": "/Users/obito/Desktop/business/jezero-content-base/write-status.sh" }],
#     "PostToolUse": [{ "matcher": "Skill", "command": "/Users/obito/Desktop/business/jezero-content-base/write-status.sh" }]
#   }
# Then open index.html from disk (file://). The page polls status.js every 5 seconds.

OUT="$(cd "$(dirname "$0")" && pwd)/status.js"

python3 - "$OUT" <<'PY'
import json, sys, datetime

out = sys.argv[1]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool = data.get("tool_name", "")
inp = data.get("tool_input") or {}
skill = inp.get("skill") or inp.get("subagent_type") or tool
if not skill:
    sys.exit(0)

task = inp.get("args") or inp.get("description") or inp.get("prompt") or tool or skill
task = " ".join(str(task).split())[:60] or skill
state = "end" if data.get("hook_event_name") == "PostToolUse" else "start"
stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

payload = {"skill": skill, "task": task, "state": state, "at": stamp}
with open(out, "w") as fh:
    fh.write("window.JEZERO_STATUS = " + json.dumps(payload) + ";\n")
PY

exit 0
