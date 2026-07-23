---
name: delegate-to-agent
description: Offload read-heavy / context-heavy work OFF Claude's own context by delegating it to ANOTHER agent — codebase search ("where is X defined / used", "how does subsystem Y work"), digesting huge logs / build output / generated files, indexing docs, first-pass RU↔EN translation, proofreading, second-opinion critique, bulk fixture/data extraction. The other agent reads a lot in ITS own context and returns a compact answer; Claude keeps its context clean. Delegation channels: (1) a LOCAL AI CLI (`<cli> -p "..."`) — automatic but quota-bound (Gemini CLI free-tier = 20 requests/day TOTAL, verified); (2) Antigravity paste-relay — the owner copy-pastes a brief into the Antigravity agentic IDE (repo-access + web, sits in the same project) and pastes the result back, no quota, used when the CLI is unavailable / quota-exhausted / region-blocked. Invoke whenever a task means "read many files/pages and return a short conclusion", or on the words исследуй / где определён / где используется / просканируй / summarize / переведи / второе мнение / раскритикуй / большой лог / делегируй / другой агент / cli / gemini / codex / antigravity / экономь токены. NOT for writing production code, architecture decisions, or applying this repo's conventions — those stay in Claude. For LIVE WEB / deep research (delegating to a browsing chat/site) use the sibling delegate-web-research. Documents per-channel setup and how failures surface to the owner.
---

# Skill: delegate-to-agent

**Division of labor:** another agent (a local CLI, or Antigravity via paste-relay) is the cheap **bulk reader**; Claude is the **writer / decider / reviewer**. Anything that means *read a lot → return a little* goes to the other agent, in its own context, so Claude's context stays clean. Everything that means *apply our conventions, decide, or write final output* stays in Claude.

> **The other agent's output is always UNVERIFIED INPUT, never authority.** A weaker/cheaper model drifts to defaults. Every result is spot-checked before it is acted on or quoted; never cited as the source in a spec, Decision block, or arch-pack.

## Two delegation channels

**Channel 1 — a local AI CLI** (automatic, but quota-bound). Any CLI that takes a non-interactive prompt and returns text:

| Backend | Invocation | Status |
|---|---|---|
| **Gemini CLI** | `gemini -m gemini-flash-latest -p "<prompt>"` | ✅ verified (2026-07-23) — free-tier = **20 req/day TOTAL** — see "Backend: Gemini CLI" |
| **OpenAI Codex / ChatGPT CLI** | e.g. `codex exec "<prompt>"` (verify flags live) | ❌ no free tier — login needs phone; paid only (2026-07-23) |
| **Any other local AI CLI** | `<cli> <non-interactive-prompt-flag> "<prompt>"` | plug in via the same Step 0 / verify / failure shape |

Pick whichever is installed + authed on the machine. The **pattern is identical**; only the binary name, the prompt flag, and the setup differ. Confirm exact flags with `<cli> --help` on first use — do not assume.

**Channel 2 — Antigravity paste-relay** (no quota; owner does the copy-paste). The Antigravity agentic IDE has **repo access + web**, so it can do every local pattern below (it reads our files in its own context) AND web research. Use it as the **fallback whenever the CLI is down** (quota-exhausted / not installed / region-blocked), or whenever the read volume is big enough that spending Claude's context is the real cost. See "Backend: Antigravity paste-relay". The bridge is **manual copy-paste** — there is no API into it — so delegate here when the token saving outweighs the paste effort (big reads), not for trivia.

## When this fires

Read-heavy / context-heavy **local** work: codebase search ("where is X defined / used", "how does Y work across N files"); digesting a huge log / build output / generated file; indexing a directory (`docs/architecture/*`); first-pass RU↔EN translation or proofreading; a cheap independent second opinion; bulk extraction of structured data. Trigger words: исследуй / где определён / где используется / просканируй / summarize / переведи / второе мнение / раскритикуй / большой лог / делегируй / cli / gemini / codex.

> **Needs the live internet?** (web research, current versions, "find libraries", competitive survey) → use [`delegate-web-research`](../delegate-web-research/SKILL.md). Local CLIs' free tiers usually can't browse (e.g. Gemini CLI free-tier web-search = 429).

## Step 0 — Preflight (ALWAYS run before delegating)

Probe availability first, **always under an OS timeout** — a busy model can trigger the CLI's own retry-with-backoff (~90 s), which reads as a "hang". On failure, do NOT silently fall back to burning Claude's own context — surface it to the owner (see "Failure reporting"). Cache the probe result for the session (probe once, not before every call).

```bash
timeout 15 <cli> --version                 # installed? (command-not-found ⇒ not installed) — instant, no network
timeout 25 <cli> <prompt-flag> "reply OK"  # auth + network + model — NEVER without a timeout
```

## Step 1 — Pick the delegation pattern

Run the CLI **inside the project directory** so it has file access (its own read/grep/glob tools + large context). Always tell it **"do not modify any files, read only"** and **"return file:line + one-line role, be terse"**.

- **A. Codebase search & comprehension** — "Find where 'X' is defined and every place it's used. Return file:line + one-line role. Read only." / "Explain how <Y> works across the codebase: entry points, main types, data flow. Cite file:line. Terse."
- **B. Logs & build output** — "From this build log, list only the real errors, clustered by root cause. Ignore noise." `< build.log`; summarize a long `git log` / large diff into themes.
- **C. Translation & text** — first-pass RU↔EN of spec strings (pairs with `procedure-translate-spec-strings`); proofread an owner-facing Russian passage; summarize a long spec / backlog task.
- **D. Second opinion / adversarial check** — "Critique this plan as an independent reviewer. What's wrong, risky, or missing? <plan>" — cheap divergent perspective before Claude commits.
- **E. Bulk mechanical** — generate test fixtures / sample data; extract structured data from unstructured text into a table.

## Step 2 — Verify (MANDATORY, never skip)

- **Code/factual claims:** Read the cited `file:line` and confirm before acting. If it can't be confirmed, treat the claim as false.
- **Research/comprehension:** prefer a primary source (RFC / spec / real code) over the CLI's paraphrase — per `procedure-architecture-sourcing`, research wins on conflict, and a local CLI is not a primary source.
- **Anything touching crypto / wire-format / domain-isolation / a Decision:** the CLI is input only. The authority is the arch-pack + primary sources.

## Privacy guard (HARD)

The CLI sends whatever you feed it to its vendor. **Never** pipe/`@`-include: `.env`, private keys, `google-services.json`, service-account JSON, JWT/API tokens, user PII, or any secret. Source files for search/comprehension are acceptable (the owner installed the CLI deliberately); secrets are not.

## When NOT to delegate (stays in Claude)

Writing production code; architecture / one-way-door decisions; applying this repo's conventions (rules 1–14, wire-format, backlog format); final owner-facing decisions; anything where a wrong-but-plausible answer is expensive to catch. The CLI can *gather* for these, but Claude *writes and decides*.

## Failure reporting (make it visible to the owner)

On ANY CLI failure, emit ONE Russian status line to the owner and STOP — do not silently spend Claude context instead:

```
⚠️ <CLI> недоступен (<причина>). Варианты:
  [1] Исправить: <точная команда>
  [2] Antigravity paste-relay — соберу brief, вставишь в Antigravity, вернёшь результат (ноль токенов Claude)
  [3] Прочитать самому Claude (дороже по контексту) — спрошу подтверждение
  [4] Пропустить
```

For a quota-exhausted / not-installed / region-blocked CLI, **[2] Antigravity paste-relay is the preferred fallback** — it costs zero Claude context, same as the CLI would. Only offer [3] (Claude reads directly) when the read is small or the owner declines the paste. Never auto-fall-back to Claude's own web tools — the whole point is to not spend that context.

---

## Backend: Gemini CLI (verified 2026-07-23)

Invocation: **`gemini -m gemini-flash-latest -p "<prompt>"`**. Non-interactive form. Windows key gotcha (`setx` doesn't reach the current shell):
```bash
export GEMINI_API_KEY="$(powershell.exe -NoProfile -Command "[Environment]::GetEnvironmentVariable('GEMINI_API_KEY','User')" | tr -d '\r')"
```

**Free-tier reality — the capability boundary (verified 2026-07-23):**
- ✅ **Local patterns (A–E) work on `gemini-flash-latest`** — it uses its own file tools (grep/glob/read) accurately and returns terse `file:line`.
- ⚠️ **But the whole free tier is a hard 20 requests/day TOTAL** (`generate_content_free_tier_requests, limit: 20`), shared across ALL calls — file-search included, not only web. Once spent, EVERY call (even `reply OK`) returns `429` until the ~24 h reset. So the CLI is good for a handful of delegations/day, not sustained work. Confirmed empirically: after ~20 calls a plain non-web prompt also 429s.
- ❌ **Web research never works free** — the web-search grounding call 429s on a separate web quota even before the daily cap. This is NOT 503, NOT geo/VPN.
- ➡️ **When the CLI is quota-dead, do not fall back to burning Claude's context — fall back to Channel 2 (Antigravity paste-relay).** Web work → [`delegate-web-research`](../delegate-web-research/SKILL.md).

**Model gotcha**: `gemini-2.5-flash` now returns **404** on newer keys; pro/2.0 → `429`/`503`. Use **`gemini-flash-latest`**. List a key's models: `GET https://generativelanguage.googleapis.com/v1beta/models?key=KEY`; test one: `POST …/models/<m>:generateContent?key=KEY` (200 ok / 404 gone / 429 quota / 503 busy / 400·403 bad key).

**Cause → line (failure reporting):**
- command-not-found → `не установлен` → `npm install -g @google/gemini-cli`
- `400·403 API key not valid` → `не задан / неверный ключ` → free key at aistudio.google.com; set `GEMINI_API_KEY`
- fast `403`/`400` `location`/`FAILED_PRECONDITION` → `Gemini заблокирован в регионе (РФ) — нужен VPN` (fast — no VPN-probing loop)
- `429` on web-search → `исчерпана free-tier веб-квота` → `delegate-web-research` or WebFetch or billing
- slow/backoff `503 high demand` → `модель перегружена, setup исправен — позже` (OS timeout cuts the backoff)
- `404` on model → `имя модели устарело` → `gemini-flash-latest`

**Setup on a new machine** (Node 18+):
1. `npm install -g @google/gemini-cli`
2. Free API key at aistudio.google.com → `setx GEMINI_API_KEY "<key>"` (or `~/.gemini/.env`). The OAuth "Login with Google" for individuals is disabled by Google — API key is the path. Key is a per-machine **secret** — never commit / never paste in chat.
3. Force auth type (a leftover OAuth attempt overrides the key with `IneligibleTierError`) — `~/.gemini/settings.json`: `{ "security": { "auth": { "selectedType": "gemini-api-key" } } }`
4. **Trusted-folder gotcha** (`exit 55`, "not running in a trusted directory"): trust a **parent** once — subpath match covers every project under it. `~/.gemini/trustedFolders.json`: `{ "C:\\work": "TRUST_FOLDER" }` (`TRUST_FOLDER` = folder + nested; `TRUST_PARENT` = dir above; longest match wins). Headless: env `GEMINI_CLI_TRUST_WORKSPACE=true` or `gemini --skip-trust`.
5. **Billing (only if web research needed):** key is **Free tier** until you attach Cloud billing at aistudio.google.com/apikey. A **Pro consumer subscription does NOT do this** (separate product). Paid Tier-1 removes the web-search `429`; Flash ≈ 1–2¢/call.
6. Verify: `timeout 15 gemini --version` then `timeout 25 gemini -m gemini-flash-latest -p "reply OK"`.

## Backend: OpenAI Codex / ChatGPT CLI (paid only — ruled out for free delegation, 2026-07-23)

Same delegation pattern in principle, but **not usable as a free backend**: OpenAI has no free API/CLI tier, and `codex login` demands phone verification even for a free ChatGPT account (verified — owner declined). Only revisit if the owner acquires a ChatGPT Plus/Pro sub or a funded API key; then run `codex --help`, confirm the exec/read-only/model/auth flags, and plug into Step 0 + patterns A–E + verify + a `Cause → line` block. Keep secrets out (Privacy guard).

## Backend: Antigravity paste-relay (no quota — the token-saving fallback)

Antigravity is an **agentic IDE with repo access + web**. Because it can read our files in ITS own context, it does every local pattern (A–E) as well as web research — the difference from a CLI is only the transport: **manual copy-paste by the owner**, no API, no quota. This is the channel to reach for when the CLI is quota-dead (see Gemini 20/day) or when a read is big enough that Claude's context is the real cost.

**Preconditions to tell the owner:** Antigravity open, **agent mode**, and for local-only work it needs the repo folder open (so it can `Analyzed <file>`); for web add **Web Tools ON**. Confirm it actually read/searched (trace shows `Analyzed <path>` / `Searched web for "..."`), not answered from memory.

### When to spend a paste-relay (the threshold — DECIDE before offering it)

The paste-relay costs the owner a manual copy-paste, so it earns its keep only on **big reads**. Delegate here when **at least one** holds:
- the answer requires reading **many files / a whole subsystem / a big directory** (≫ what Claude would skim), OR
- a **large log / build output / generated file / long diff** must be digested to a short conclusion, OR
- Claude's context is **already tight** and the read would crowd out the real work, OR
- the **CLI is quota-dead** (Gemini 20/day) and this is the only free channel.

Do NOT paste-relay a **small** read (one known file, a couple of symbols, a short passage) — there the paste effort beats the saving; just read it in Claude. Same discipline as [`delegate-web-research`](../delegate-web-research/SKILL.md): reserve the relay for the heavy lifts, not trivia.

### Launch plan (hand this to the owner every time — mirrors the web-research flow)

1. **Claude assembles the brief** (template below) — self-contained, names exact paths, states the pattern (A–E) and a strict return contract. Big enough to be worth a relay.
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

| Task | Token win | CLI (ch.1) | Antigravity (ch.2) |
|---|---|---|---|
| Codebase search — "where is X defined / used" | high | ✅ | ✅ (repo access) |
| Codebase comprehension — "how does Y work across N files" | high | ✅ | ✅ |
| Digest a huge log / build output / generated file | high | ✅ (`< file`) | ✅ (paste log, or it reads the file) |
| Index a docs directory (`docs/architecture/*`) | high | ✅ | ✅ |
| First-pass RU↔EN translation of a long passage | medium | ✅ | ✅ (no repo needed) |
| Second opinion / adversarial critique of a plan | medium | ✅ | ✅ (cross-model perspective) |
| Bulk fixture / sample-data / structured extraction | medium | ✅ | ✅ |
| Live web / deep research | — | ❌ (free tier) | ✅ → use `delegate-web-research` |
| **Writing prod code / arch decisions / applying repo rules / crypto·wire-format / final owner decisions** | — | ❌ stays in Claude | ❌ stays in Claude |

**Rule of thumb:** delegate the *reading*, keep the *deciding*. The delegate gathers and compresses; Claude verifies, applies conventions (rules 1–14), and writes the final artifact.

## Related
- [`delegate-web-research`](../delegate-web-research/SKILL.md) — the **web / deep-research** counterpart (paste-relay to any browsing chat/agent) when a local CLI can't browse.
- `procedure-translate-spec-strings` — a CLI can do the first-pass; that skill governs it.
- `procedure-architecture-sourcing` — research from primary sources; the CLI sweeps, Claude verifies.
- `mentor` — discussion mode; a CLI can supply a cheap second opinion inside it.
