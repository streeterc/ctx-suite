---
name: roadmap
description: View or update the project roadmap in .context/ROADMAP.md (Now / Next / Later / Done). Use when the user asks what's planned, wants to add, move, or tick an item, or asks "what should I work on next".
argument-hint: "[show | add <item> [now|next|later] | done <item> | move <item> <section>]"
---

- **show** or no args: read `.context/ROADMAP.md` and print the Now and Next sections (add Later only if asked). If asked what to work on next, recommend one item from Now, using STATE.md.
- **add / done / move**: make the edit directly with Edit. One-line changes stay inline; don't spawn a subagent. Add new items under the section given (default: Next). For `done`, tick the item and move it to Done with today's date (`date +%F`).
- If the user wants a bigger reorganisation or re-prioritisation, suggest /ctx:curate.
