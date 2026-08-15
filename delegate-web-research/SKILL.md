---
name: delegate-web-research
description: Manual copy-paste relay to Antigravity (the owner's agentic IDE — repo access + web) for LIVE WEB / DEEP RESEARCH. Claude PRINTS a self-contained brief into the chat → the owner pastes it into Antigravity, runs the research there, and pastes the answer back → Claude AUDITS and merges it. Claude NEVER runs the research itself: no local AI CLI (Gemini CLI and friends are useless here — free-tier web-search 429s), no Claude subagents, no WebSearch/WebFetch, unless the owner explicitly asks for that instead. Invoke whenever a task needs live web research, "find ready libraries/SDKs", competitive / prior-art survey, deep-research, or verifying current versions / spec status / standard numbers. NOT for writing code or final decisions — the external agent gathers, Claude verifies against primary sources (+ arch-packs) and decides. Ensemble pattern: a deeper "Pro/Thinking" tier = judgment, a faster tier = breadth; the owner can run both, Claude merges. Trigger words: research / найди в интернете / deep research / депрессёрч / актуальная версия / готовая библиотека / prior art / second opinion + web.
---

# Skill: delegate-web-research

**Division of labor:** Antigravity is the **bulk researcher**; Claude is the **auditor / decider**. It is the web/deep-research counterpart to [`delegate-to-agent`](../delegate-to-agent/SKILL.md) — reach here whenever the work needs the **internet**.

> **The external agent's output is always UNVERIFIED INPUT, never authority.** Verify against primary sources (+ our arch-packs). Every result is audited before it is acted on or quoted; never cited as the source in a spec, Decision block, or arch-pack.

## HARD: Claude prints the brief, Claude does not research (owner decision 2026-07-26)

Claude's ONLY move in this skill is **printing the brief into the chat**. Do NOT, unless the owner explicitly asks for that instead:

- ❌ run a local AI CLI (`gemini -p …` and friends) — free-tier web-search 429s, so CLI web research is **useless**; do not even preflight it for a web task;
- ❌ spawn Claude subagents (`Agent` tool) to do the searching — that burns the context this skill exists to save;
- ❌ call `WebSearch` / `WebFetch` yourself.

The owner copy-pastes the brief into Antigravity, runs the research there, and pastes the result back. That paste-back is the input Claude audits.

## The target: Antigravity (agentic IDE — repo access + web)

Any other web-capable chat (ChatGPT, Gemini, Perplexity, Claude-with-web) works as a **secondary** target if the owner names one — but then it has **no repo access**, so every constraint must be restated **inline** in the brief. Antigravity is the default: it can both `Analyzed <file>` our arch-packs and `Searched web`.

There is **no external API into these chats** — the bridge is **manual copy-paste** by the owner. (Automating an Electron IDE chat via CDP is possible but brittle/ToS-grey — a backlog task, not a default.)

## Preconditions (tell the owner)

- Antigravity **open**, in **agent mode**, with **Web Tools ON**; browsing is a **tool**, not a selectable "model".
- Repo folder open → use the repo-aware brief (point at exact files). For a no-repo target → same brief, but paste the relevant constraints/decisions inline.

## The step-by-step launch plan (hand this to the owner EVERY time)

1. **Claude prints the brief into the chat** (template below) — self-contained, no secrets, demands inline deep-link URLs + a browsing-proof section. Repo-access target → point at exact files; no-repo target → inline the constraints.
2. **Owner pastes it into Antigravity.** Model choice (ensemble):
   - a **deeper "Pro / Thinking" tier** → architectural **judgment**;
   - a **faster tier** → wider **retrieval breadth** (more searches, versions, obscure repos). *Newer number ≠ smarter — a "Flash/mini" tier is lighter than a "Pro/Thinking" tier; they are complementary.*
   - Default: run **two** (deep + fast). Optional 3rd **cross-family** (a different vendor's model) only for one-way-door decisions.
3. **Owner confirms it actually browsed**: the trace shows search/fetch steps (e.g. `Searched web for "..."`). If it answered in seconds with no search trace, or "URLs" are homepage roots, or numbers differ run-to-run → it guessed from memory; re-run with the browsing-proof clause enforced (and web-tools ON).
4. **Owner pastes ALL runs back to Claude.**
5. **Claude audits + merges** → one verified result.

## Ensemble + audit (Claude merges — not a model)

- **Agreement across runs = high confidence** — take it.
- **Divergence = the signal** — exactly what Claude verifies against a primary source (+ arch-pack). Merge = **union of findings + verification of the divergences**, not averaging.
- The audit is **Claude's** job: verifying against repo conventions (rules 11/14) and primary sources is Claude's role; a model auditing its siblings drifts to consensus.

## Verify (MANDATORY, never skip)

- Cross-check every factual claim (versions, licenses, standard/spec numbers, "library X ships Y") against a **primary source** (+ our arch-pack). Run-to-run inconsistency marks the least-reliable facts — verify those first.
- Anything touching crypto / wire-format / domain-isolation / a Decision: the external agent is input only; the authority is the arch-pack + primary sources.
- Arch-pack changes that follow go through rules 11/14 (Decision process + same-commit arch-pack update) — never edit an arch-pack straight from an external-agent result.

### Known failure modes (observed 2026-08-12, a large media-domain harvest)

- **Self-rated confidence does not correlate with verifiability.** A run stamped its own machine-readable summary `scale_numbers_accuracy: 1.00` while **two** of its cited URLs returned 404. Its own retrieval trace showed the mechanism: a query of the form `"<product> limits" "5000" "100 subscribers"` — the numbers were already in the model's memory and the search went looking for a **confirming link**, not for the fact. Symptom to grep for: plausible numbers next to a dead URL. **Never carry a number whose URL you have not personally opened.**
- **Trust the prose, distrust the summary.** The same run's summary asserted `all_implementable_under_zk: true` while its own body described two ways it does not work. Machine-readable blocks are written last and drift optimistic.
- **A row-count target in the brief buys padding, not coverage.** Asked for 120 rows, a weak run returned 31 real ones plus openly-labelled synthetic ranges ("`I51-I70` synthesizes … to meet the 120-row request") — ~74 % of the claimed catalogue did not exist. Another padded with implementation techniques (SDK classes, framework flags) rather than observed use cases. **Never state a target count; state the axes to cover and ask for saturation** ("stop when new rows stop producing new forms"), and explicitly forbid implementation techniques when harvesting use cases.
- **"Deep URLs opened (via search summaries)" means the pages were never opened.** Look for that phrasing in the retrieval-evidence section; treat the whole run as snippet-level.
- **Anchoring destroys the negative result.** If the brief supplies a taxonomy and asks the run to classify against it, "no new categories found" is **absence of a counterexample under directed search**, not evidence of completeness. An unanchored run on the same material found four. Record the caveat next to any completeness claim earned this way; if completeness actually matters, one run must be unanchored.

## Privacy guard (HARD)

The brief may reference repo **architecture files** (only for a target the owner opened on the repo deliberately) or restate decisions inline — but **never** paste secrets: `.env`, keys, `google-services.json`, service-account JSON, tokens, user PII.

## The brief template

Fill the `<…>` slots; keep the headings so paste-back is structured and diffable. For a **no-repo** target, replace STEP 1 file paths with the decisions restated inline under "OUR HARD CONSTRAINTS".

```
ROLE: You are a senior research assistant. Do WEB RESEARCH and cite every external claim with an INLINE deep-link URL (the specific page, not a homepage). Prefer primary sources. Flag anything uncertain or outdated.
[repo-access target only] You ALSO have access to this repository — first READ the files below (our current "read-truth"), then research the web to verify and CHALLENGE them.

STEP 1 — READ THESE REPO FILES (repo-access target only):
- <path/to/arch-pack-1.md>   (<one-line what it decides>)
- <path/to/arch-pack-2.md>   (<...>)
- <CONVENTIONS file> rules <N, M>   (<the constraints that matter>)

OUR HARD CONSTRAINTS (restate here — MANDATORY for a no-repo target):
1. <constraint — e.g. zero-knowledge server: server sees only opaque blobs>
2. <constraint — e.g. self-hostable, non-GPL/AGPL for shipped code>
3. <what we already decided, so you confirm-or-challenge rather than start from zero>

THE QUESTION: <sharp question that uses our actual position, not a generic survey>

DELIVER (use these exact headings):
## 1. <…>
## 2. <…>
## 3. Option matrix — a table: rows = options, cols = <…>, cells = <verdict vocabulary>
## 4. Recommendation — one concrete pick, main trade-off, biggest risk
## 5. Where you AGREE / DISAGREE with our position  ← MOST VALUABLE: be a critical reviewer; what evidence SUPPORTS vs what looks OUTDATED/WRONG
## 6. Machine-readable summary — compact key:value block for diffing
## 7. Retrieval evidence — the exact search queries you ran and the deep URLs you opened

RETURN CONTRACT: structured with the headings above; INLINE deep-link URLs MANDATORY; flag every uncertain claim; if you did NOT browse for a fact, mark it "(from memory, unverified)". Research input only; do not modify any files.
```

## When NOT to use this

Writing code; final architecture / one-way-door decisions (the agent may gather, Claude decides); anything a plain local file-read answers (no web needed → `delegate-to-agent` or Claude directly); tasks needing secrets.

## Related
- [`delegate-to-agent`](../delegate-to-agent/SKILL.md) — local/offline delegation (same Antigravity paste-relay, repo reading, no web); this skill is its web/deep-research sibling.
- `procedure-architecture-sourcing` — research from primary sources; the external agent sweeps, Claude verifies.
- `mentor` — discussion mode; an external run can supply a cross-model second opinion inside it.
