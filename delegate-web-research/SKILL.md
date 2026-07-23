---
name: delegate-web-research
description: Manual copy-paste relay to ANY web-capable chat or agent for LIVE WEB / DEEP RESEARCH that a local AI CLI's free tier cannot do (e.g. Gemini CLI web-search returns 429). The target can be ANY place the owner pastes a prompt and the agent browses the internet — a browsing chat (ChatGPT, Gemini, Perplexity, Claude) or an agentic IDE (Antigravity and similar) that ALSO reads the repo. Claude assembles a self-contained brief → the owner pastes it into the chosen chat/agent, picks the model(s), and pastes the answer back → Claude AUDITS and merges it. Invoke whenever a task needs live web research, "find ready libraries/SDKs", competitive / prior-art survey, deep-research, or verifying current versions / spec status / standard numbers — and no local browsing backend is available. NOT for writing code or final decisions — the external agent gathers, Claude verifies against primary sources (+ arch-packs) and decides. Ensemble pattern: a deeper "Pro/Thinking" tier = judgment, a faster tier = breadth; run both, Claude merges. Trigger words: research / найди в интернете / deep research / депрессёрч / актуальная версия / готовая библиотека / prior art / second opinion + web.
---

# Skill: delegate-web-research

**Division of labor:** the external web-capable agent is the **bulk researcher**; Claude is the **auditor / decider**. It is the web/deep-research counterpart to [`delegate-to-agent`](../delegate-to-agent/SKILL.md) — reach here when the work needs the **internet** and no local CLI can browse (e.g. Gemini CLI free-tier web-search = 429).

> **The external agent's output is always UNVERIFIED INPUT, never authority.** Verify against primary sources (+ our arch-packs). Every result is audited before it is acted on or quoted; never cited as the source in a spec, Decision block, or arch-pack.

## The target is ANY web-capable chat/agent (pick what the owner has)

| Kind | Examples | Repo access? |
|---|---|---|
| **Agentic IDE** (reads the repo + browses) | Antigravity, other agentic IDE forks | ✅ yes — can `Analyzed <file>` our arch-packs AND `Searched web` |
| **Browsing chat** (browses, no repo access) | ChatGPT, Gemini, Perplexity, Claude with web | ❌ no — cannot read repo files; constraints must go **inline** in the brief |

There is **no external API into these chats** — the bridge is **manual copy-paste** by the owner. (Automating an Electron IDE chat via CDP is possible but brittle/ToS-grey — a backlog task, not a default.)

## Preconditions (tell the owner)

- The chosen tool is **open and web-enabled**. For an agentic IDE: **agent mode** + its **web-tools setting ON** (e.g. Antigravity's "Agent Web Tools"); browsing is usually a **tool**, not a selectable "model".
- If the target has **repo access** (agentic IDE): use the repo-aware brief (points at files). If **not** (plain browsing chat): use the same brief but **paste the relevant constraints/decisions inline** — it can't open our files.

## The step-by-step launch plan (hand this to the owner EVERY time)

1. **Claude assembles the brief** (template below) — self-contained, no secrets, demands inline deep-link URLs + a browsing-proof section. Repo-access target → point at exact files; no-repo target → inline the constraints.
2. **Owner pastes it into the chosen chat/agent.** Model choice (ensemble):
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
- [`delegate-to-agent`](../delegate-to-agent/SKILL.md) — local/offline delegation (a local AI CLI, or Antigravity paste-relay, no web); this skill is its web/deep-research sibling.
- `procedure-architecture-sourcing` — research from primary sources; the external agent sweeps, Claude verifies.
- `mentor` — discussion mode; an external run can supply a cross-model second opinion inside it.
