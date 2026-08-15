---
name: delegate-to-agent
description: Offload read-heavy / context-heavy work OFF Claude's own context by delegating it to Antigravity (the owner's agentic IDE, repo access + web) — codebase search ("where is X defined / used", "how does subsystem Y work"), digesting huge logs / build output / generated files, indexing docs, first-pass RU↔EN translation, proofreading, second-opinion critique, bulk fixture/data extraction. Antigravity reads a lot in ITS own context and returns a compact answer; Claude keeps its context clean. ONE channel: Claude PRINTS a brief into the chat, the owner pastes it into Antigravity and pastes the result back. Local AI CLIs (Gemini CLI, codex) are RETIRED — do not invoke them. Invoke whenever a task means "read many files/pages and return a short conclusion", or on the words исследуй / где определён / где используется / просканируй / summarize / переведи / второе мнение / раскритикуй / большой лог / делегируй / другой агент / antigravity / экономь токены. NOT for writing production code, architecture decisions, or applying this repo's conventions — those stay in Claude. For LIVE WEB / deep research use the sibling delegate-web-research.
---

# Skill: delegate-to-agent

**Division of labor:** Antigravity (via paste-relay) is the cheap **bulk reader**; Claude is the **writer / decider / reviewer**. Anything that means *read a lot → return a little* goes to it, in its own context, so Claude's context stays clean. Everything that means *apply our conventions, decide, or write final output* stays in Claude.

> **The other agent's output is always UNVERIFIED INPUT, never authority.** A weaker/cheaper model drifts to defaults. Every result is spot-checked before it is acted on or quoted; never cited as the source in a spec, Decision block, or arch-pack.

## One channel: Antigravity paste-relay (owner decision 2026-07-26)

Claude's move is **printing a brief into the chat**; the owner pastes it into Antigravity (agentic IDE, **repo access + web**, sits in the same project) and pastes the result back. No quota, zero Claude context spent on the reading.

**Local AI CLIs are RETIRED — do not invoke them.** `gemini -p …`, `codex exec …` and friends: the free tier is a hard ~20 requests/day and its web-search 429s outright, so the answer arrives late, thin, or not at all. Do not preflight them, do not fall back to them. (Kept as a tombstone so no future session re-derives this: verified 2026-07-23, retired by the owner 2026-07-26 as "useless".)

Also **do not** substitute Claude subagents (`Agent` tool) or Claude's own file-reading for a delegated read unless the owner asks — that spends exactly the context this skill exists to save.

The bridge is **manual copy-paste** — there is no API into it — so delegate when the token saving outweighs the paste effort (big reads), not for trivia.

## When this fires

Read-heavy / context-heavy **local** work: codebase search ("where is X defined / used", "how does Y work across N files"); digesting a huge log / build output / generated file; indexing a directory (`docs/architecture/*`); first-pass RU↔EN translation or proofreading; a cheap independent second opinion; bulk extraction of structured data. Trigger words: исследуй / где определён / где используется / просканируй / summarize / переведи / второе мнение / раскритикуй / большой лог / делегируй / cli / gemini / codex.

> **Needs the live internet?** (web research, current versions, "find libraries", competitive survey) → use [`delegate-web-research`](../delegate-web-research/SKILL.md). Local CLIs' free tiers usually can't browse (e.g. Gemini CLI free-tier web-search = 429).

## Step 0 — Is the read big enough to relay?

No preflight, no probing — the channel is the owner. Just decide whether the read clears the threshold (see "When to spend a paste-relay"). If it does not, read it in Claude and move on.

## Step 1 — Pick the delegation pattern

The brief always says **"do not modify any files, read only"** and **"return file:line + one-line role, be terse"**.

- **A. Codebase search & comprehension** — "Find where 'X' is defined and every place it's used. Return file:line + one-line role. Read only." / "Explain how <Y> works across the codebase: entry points, main types, data flow. Cite file:line. Terse."
- **B. Logs & build output** — "From this build log, list only the real errors, clustered by root cause. Ignore noise." `< build.log`; summarize a long `git log` / large diff into themes.
- **C. Translation & text** — first-pass RU↔EN of spec strings (pairs with `procedure-translate-spec-strings`); proofread an owner-facing Russian passage; summarize a long spec / backlog task.
- **D. Second opinion / adversarial check** — "Critique this plan as an independent reviewer. What's wrong, risky, or missing? <plan>" — cheap divergent perspective before Claude commits.
- **E. Bulk mechanical** — generate test fixtures / sample data; extract structured data from unstructured text into a table.

## Step 2 — Verify (MANDATORY, never skip)

- **Code/factual claims:** Read the cited `file:line` and confirm before acting. If it can't be confirmed, treat the claim as false.
- **Research/comprehension:** prefer a primary source (RFC / spec / real code) over the delegate's paraphrase — per `procedure-architecture-sourcing`, research wins on conflict, and a chat agent is not a primary source.
- **Anything touching crypto / wire-format / domain-isolation / a Decision:** the delegate is input only. The authority is the arch-pack + primary sources.

## Privacy guard (HARD)

The brief goes to an external vendor. The repo is fair game (the owner opened it there deliberately); **never** restate: `.env`, private keys, `google-services.json`, service-account JSON, JWT/API tokens, user PII, or any secret.

## When NOT to delegate (stays in Claude)

Writing production code; architecture / one-way-door decisions; applying this repo's conventions (rules 1–14, wire-format, backlog format); final owner-facing decisions; anything where a wrong-but-plausible answer is expensive to catch. The delegate can *gather* for these, but Claude *writes and decides*.

## If the relay stalls

The only failure mode left is the owner not running it (busy, Antigravity closed, result looks like it never browsed/read). Then emit ONE Russian line and STOP:

```
⚠️ Antigravity-релей не вернул результат. Варианты:
  [1] Перезапустить бриф в Antigravity (agent mode, Web Tools ON / репо открыто)
  [2] Прочитать самому Claude (дороже по контексту) — спрошу подтверждение
  [3] Пропустить
```

Never auto-fall-back to Claude's own reading or web tools — the whole point is to not spend that context.

---

## Retired backends — do not re-derive (tombstone)

**Local AI CLIs are out**, by owner decision 2026-07-26 ("бесполезны"). Do not install, probe, or invoke them; do not offer them as an option.

- **Gemini CLI** (`gemini -m gemini-flash-latest -p …`) — worked mechanically, but the free tier is a hard **20 requests/day TOTAL** (`generate_content_free_tier_requests, limit: 20`, shared across every call), and **web-search grounding 429s on its own quota before the daily cap is even reached**. Verified 2026-07-23.
- **OpenAI Codex / ChatGPT CLI** — no free API/CLI tier; `codex login` demands phone verification. Verified 2026-07-23, owner declined.

## Backend: Antigravity paste-relay (the only channel)

Antigravity is an **agentic IDE with repo access + web**. Because it can read our files in ITS own context, it does every local pattern (A–E) as well as web research; the transport is **manual copy-paste by the owner**, no API, no quota. Reach for it when a read is big enough that Claude's context is the real cost.

**Preconditions to tell the owner:** Antigravity open, **agent mode**, and for local-only work it needs the repo folder open (so it can `Analyzed <file>`); for web add **Web Tools ON**. Confirm it actually read/searched (trace shows `Analyzed <path>` / `Searched web for "..."`), not answered from memory.

### When to spend a paste-relay (the threshold — DECIDE before offering it)

The paste-relay costs the owner a manual copy-paste, so it earns its keep only on **big reads**. Delegate here when **at least one** holds:
- the answer requires reading **many files / a whole subsystem / a big directory** (≫ what Claude would skim), OR
- a **large log / build output / generated file / long diff** must be digested to a short conclusion, OR
- Claude's context is **already tight** and the read would crowd out the real work.

Do NOT paste-relay a **small** read (one known file, a couple of symbols, a short passage) — there the paste effort beats the saving; just read it in Claude. Same discipline as [`delegate-web-research`](../delegate-web-research/SKILL.md): reserve the relay for the heavy lifts, not trivia.

### Launch plan (hand this to the owner every time — mirrors the web-research flow)

1. **Claude prints the brief into the chat** (template below) — self-contained, names exact paths, states the pattern (A–E) and a strict return contract. Big enough to be worth a relay.
2. **Owner pastes it into Antigravity** (agent mode; repo open; Web Tools ON only if the brief also needs web).
3. **Owner confirms it actually worked the repo** — the trace shows `Analyzed <path>` / grep steps. If it answered in seconds with no file-open trace → it guessed from memory; re-run.
4. **Owner pastes the whole result back to Claude.**
5. **Claude verifies + integrates** (Step 2 — the paste-back is UNVERIFIED INPUT exactly like CLI output; spot-check cited `file:line`, apply repo conventions, write the final artifact). The delegate returns *compressed findings*; Claude turns them into the *decision / code / spec*.

**Local-work brief template** (repo-access target — point at exact paths, it reads them itself):

```
ROLE: You have access to this repository. READ ONLY — do not modify any file.
TASK: <pick a pattern — e.g. "Find where `FooPort` is defined and every call site."
       / "Explain how <subsystem> works across the codebase: entry points, main types, data flow."
       / "From build.log below, list the real errors clustered by root cause.">
READ THESE (start here, expand as needed):
- <path/or/dir 1>
- <path/or/dir 2>
RETURN CONTRACT: terse; cite `file:line` for every claim; one-line role per symbol; a compact
summary at the end. If you did not open a file for a claim, mark it "(unverified)". No prose padding.
```

For web briefs use [`delegate-web-research`](../delegate-web-research/SKILL.md)'s template instead — same channel, that skill owns the web-specific contract (inline URLs, browsing-proof).

**Privacy guard applies unchanged:** the repo is fair game (owner opened it deliberately), secrets are NOT — never restate `.env` / keys / `google-services.json` / tokens / PII in a brief.

## What to delegate (token-saving map) — and what stays in Claude

Delegate when **read volume is high** (the win is real); keep in Claude when a wrong-but-plausible answer is expensive or the read is trivial (paste effort > saving).

| Task | Token win | Antigravity paste-relay |
|---|---|---|
| Codebase search — "where is X defined / used" | high | ✅ (repo access) |
| Codebase comprehension — "how does Y work across N files" | high | ✅ |
| Digest a huge log / build output / generated file | high | ✅ (paste log, or it reads the file) |
| Index a docs directory (`docs/architecture/*`) | high | ✅ |
| First-pass RU↔EN translation of a long passage | medium | ✅ (no repo needed) |
| Second opinion / adversarial critique of a plan | medium | ✅ (cross-model perspective) |
| Bulk fixture / sample-data / structured extraction | medium | ✅ |
| Live web / deep research | — | ✅ → use `delegate-web-research` |
| **Writing prod code / arch decisions / applying repo rules / crypto·wire-format / final owner decisions** | — | ❌ stays in Claude |

**Rule of thumb:** delegate the *reading*, keep the *deciding*. The delegate gathers and compresses; Claude verifies, applies conventions (rules 1–14), and writes the final artifact.

## Related
- [`delegate-web-research`](../delegate-web-research/SKILL.md) — the **web / deep-research** counterpart (same Antigravity relay, web-specific return contract).
- `procedure-translate-spec-strings` — the delegate can do the first-pass; that skill governs it.
- `procedure-architecture-sourcing` — research from primary sources; the delegate sweeps, Claude verifies.
- `mentor` — discussion mode; a relayed run can supply a cross-model second opinion inside it.
