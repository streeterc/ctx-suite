---
name: curate
description: Tidy and reconcile .context/. Archives old session logs, syncs the roadmap with git history, dedupes ideas, and trims STATE.md. Run weekly or when context feels stale.
disable-model-invocation: true
---

Curate `.context/` at the git root. The aim is a context set that stays small, accurate, and cheap to load. Read files in ranges and keep tool output small; this runs in the main conversation.

1. **Reconcile:** compare ROADMAP.md and STATE.md with `git log --since="<oldest unarchived log date>" --oneline` and the log/ files. Tick items that are done, move items between Now/Next/Later when the evidence supports it, and add any shipped work the roadmap is missing.
2. **Archive:** keep the 15 newest files in log/. Roll older ones into `log/archive/YYYY-MM.md` as one dense 3–6 line paragraph per session that keeps the decisions, gotchas, and file paths. Then delete the originals.
3. **Ideas:** merge duplicates. Move any idea that is clearly on the roadmap into ROADMAP.md (Later) and mark it `→ roadmap`. Leave the rest alone.
4. **Decisions:** if a decision has been reversed according to later logs or commits, mark it `Superseded by <date>` rather than deleting it.
5. **STATE.md:** ≤40 lines, current, and no history (history belongs in log/).
6. **Docs:** if CLAUDE.md states facts that contradict reality, list them in your report but don't edit CLAUDE.md.

Never discard information without first archiving it. Don't commit. Finish with a report of ≤10 lines: what moved, what was archived, and any conflicts that need a human decision (ask the user about those).
