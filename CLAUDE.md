# Tell Me How

A phone-first shorts feed of tiny animated "how things work" topics whose one job is to make people curious (read `PRODUCT.md` first). Topics are data files rendered by shared vanilla-JS canvas blocks and built into one HTML page.

| File | What |
|---|---|
| `PRODUCT.md` | Product goal: curiosity, effortless, broad appeal |
| `RECIPE.md` | How to write a topic (one big question, 1–6 cards); `topics/_template.js` to start |
| `core/BLOCKS.md` | Card and visual types, params |
| `topics/*.js` | One topic per file |
| `build.mjs` | `LIBRARY` list = topics in the feed |
| `tasks/todo.md`, `tasks/fix-log.md` | Plan, decisions, lessons |
| `tasks/handoff.md` | How to pick up work from another session |

**Build:** `./build.sh library` → `dist/library.html` (also `./build.sh <id>` for one topic).

**Gotchas**
- Every topic must define its own words. Topics arrive at random, so never rely on a sibling topic.
- Writers drift over ~30 words per card during fixes; trim.
- Copy is spine-first (`write-explainer` skill): facts sheet, then one paragraph the owner approves, then slides. Never paste fact-check wording into copy. Only a human new to the topic can judge clarity.
- Several sessions may edit at once: only touch your own topic files; add ids to `LIBRARY` in one small edit.
- Never republish the testers' link (https://claude.ai/artifact/47dT3dkGhANEzEWf64UFhP) without the owner's OK.
- Git: `github.com/saqlainmmomin/Polymath` (`main`). `dist/` is not committed; rebuild with `./build.sh`. Old versions also live in `archive-*`.
