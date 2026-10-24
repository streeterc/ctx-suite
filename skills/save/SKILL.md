---
name: save
argument-hint: "[optional note or focus]"
disable-model-invocation: true
description: Checkpoint the session into .context/ now (log, STATE.md, roadmap, ideas, decisions). Autosave already does this on exit and /compact; use this only to save mid-session.
---

Work inline from what you already know; don't re-read files beyond the ones you edit. Include anything from $ARGUMENTS. Record facts only; invent nothing.

1. Write `.context/log/<date +%Y-%m-%d-%H%M>-<hostname -s>.md` (≤25 lines; leave out empty sections):
   `# <date> <host> — <one-line title>`, then **Done** (what changed and why), **Changed files**,
   **Open threads / next steps** (precise: the file, function and step that was mid-flight, so a fresh session can resume), **Notes**.
2. Rewrite `.context/STATE.md` to reflect the new reality: ≤40 lines, sections Focus / In progress / Next steps / Blockers, finished items dropped, ending `Updated: <date> on <host>`.
3. With Edit: tick roadmap items that are done (append ` (<date>)`); append ideas to IDEAS.md (`- YYYY-MM-DD: idea`) and decisions to DECISIONS.md (`## YYYY-MM-DD: Title` / **Context:** / **Decision:** / **Consequences:**).
4. Reply in one line listing the files touched. Don't commit: autosave commits `.context/` when the session ends (per `autocommit` in `.context/config`). Commit now only if the user asks.
