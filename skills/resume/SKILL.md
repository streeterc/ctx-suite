---
name: resume
argument-hint: "[optional question about the project's history]"
disable-model-invocation: true
description: Briefing of where the project stands, from .context/ and git. Use after a git pull, or for more history than the start hook gives.
---

If `.context/` is missing at the git root, reply "No .context/ here; run /ctx:init" and stop. Gather everything in one Bash call, keeping output small:
STATE.md; the Now and Next sections of ROADMAP.md; the 3 newest session logs (`ls -1 .context/log/*.md | grep -E '/[0-9]{4}-..-..-[0-9]{4}-' | sort | tail -3`; this skips archives); the last 5 entries of DECISIONS.md; `git status -sb`; `git log --oneline -10`; `git log -1 --format=%cd -- .context`.

Flag drift: commits newer than the last log that it doesn't cover, STATE items the logs show are done, or a branch `behind` its remote ("git pull for latest context"). Reply in exactly this format, ≤250 words, no preamble:
```
**Focus:** …
**Last session (<date>, <host>):** …
**In progress:** - …
**Next up:** - …
**Recent decisions:** - …
**Warnings:** - … (omit if none)
```
If $ARGUMENTS asks a question, answer it from these files in ≤100 words after the briefing.
