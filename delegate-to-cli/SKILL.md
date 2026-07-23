---
name: delegate-to-cli
description: Offload read-heavy / context-heavy work to a LOCAL AI CLI (`<cli> -p "..."`) instead of spending Claude's own context on it — codebase search ("where is X defined / used", "how does subsystem Y work"), digesting huge logs / build output / generated files, indexing docs, first-pass RU↔EN translation, proofreading, second-opinion critique, bulk fixture/data extraction. The CLI reads a lot in ITS own context and returns a compact answer; Claude keeps its context clean. Backend-agnostic: Gemini CLI (`gemini -p`, verified) is the primary backend; OpenAI Codex / ChatGPT CLI and other prompt-taking CLIs plug into the same pattern. Invoke whenever a task means "read many files/pages and return a short conclusion", or on the words исследуй / где определён / где используется / просканируй / summarize / переведи / второе мнение / раскритикуй / большой лог / делегируй / cli / gemini / codex. NOT for writing production code, architecture decisions, or applying this repo's conventions — those stay in Claude. For LIVE WEB / deep research use the sibling delegate-web-research (local CLIs' free tiers usually can't browse). Documents per-backend setup and how failures surface to the owner.
---

# Skill: delegate-to-cli

**Division of labor:** a local AI CLI is the cheap **bulk reader**; Claude is the **writer / decider / reviewer**. Anything that means *read a lot → return a little* goes to the CLI, in its own context, so Claude's context stays clean. Everything that means *apply our conventions, decide, or write final output* stays in Claude.

> **The CLI's output is always UNVERIFIED INPUT, never authority.** A weaker/cheaper model drifts to defaults. Every result is spot-checked before it is acted on or quoted; never cited as the source in a spec, Decision block, or arch-pack.

## Backends (any CLI that takes a non-interactive prompt and returns text)

| Backend | Invocation | Status |
|---|---|---|
| **Gemini CLI** | `gemini -m gemini-flash-latest -p "<prompt>"` | ✅ verified (2026-07-23) — see "Backend: Gemini CLI" |
| **OpenAI Codex / ChatGPT CLI** | e.g. `codex exec "<prompt>"` (verify flags live) | ⚙️ pattern-compatible — see "Backend: OpenAI CLI" |
| **Any other local AI CLI** | `<cli> <non-interactive-prompt-flag> "<prompt>"` | plug in via the same Step 0 / verify / failure shape |

Pick whichever is installed + authed on the machine. The **pattern is identical**; only the binary name, the prompt flag, and the setup differ. Confirm exact flags with `<cli> --help` on first use — do not assume.

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
  [2] Другой backend / Claude WebFetch (дороже по контексту) — спрошу подтверждение
  [3] Пропустить
```

Never auto-fall-back to Claude's own web tools — the whole point is to not spend that context. `WebFetch`/`WebSearch` are set to **ask**, so option [2] always surfaces to the owner.

---

## Backend: Gemini CLI (verified 2026-07-23)

Invocation: **`gemini -m gemini-flash-latest -p "<prompt>"`**. Non-interactive form. Windows key gotcha (`setx` doesn't reach the current shell):
```bash
export GEMINI_API_KEY="$(powershell.exe -NoProfile -Command "[Environment]::GetEnvironmentVariable('GEMINI_API_KEY','User')" | tr -d '\r')"
```

**Free-tier reality — the capability boundary:**
- ✅ **Local patterns (A–E) work free and reliable on `gemini-flash-latest`** (empirically 6/6). It uses its own file tools (grep/glob/read) accurately and returns terse `file:line`.
- ❌ **Web research does NOT work on free tier** — the web-search grounding call returns `429 RESOURCE_EXHAUSTED` (a separate web-search quota), then backoff-hangs. Route web work to [`delegate-web-research`](../delegate-web-research/SKILL.md). This is NOT 503 and NOT geo/VPN.

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

## Backend: OpenAI Codex / ChatGPT CLI (pattern-compatible — verify live)

Same delegation pattern; only the binary + flags differ. On first use, run `<cli> --help` and confirm: the **non-interactive/exec** flag (e.g. `codex exec "<prompt>"`), how to keep it **read-only** (no auto-edit/no auto-approve), the **model** flag, and the **auth** method (API key env var). Then reuse Step 0 (bounded `--version` + one real call), the same patterns A–E, the same verify step, and add a `Cause → line` block per this CLI's error shapes (not-installed / bad-key / rate-limit / offline). Keep secrets out (Privacy guard). If its free tier can browse the web reliably, it can also serve as a backend for `delegate-web-research`.

## Related
- [`delegate-web-research`](../delegate-web-research/SKILL.md) — the **web / deep-research** counterpart (paste-relay to any browsing chat/agent) when a local CLI can't browse.
- `procedure-translate-spec-strings` — a CLI can do the first-pass; that skill governs it.
- `procedure-architecture-sourcing` — research from primary sources; the CLI sweeps, Claude verifies.
- `mentor` — discussion mode; a CLI can supply a cheap second opinion inside it.
