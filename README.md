# Personal Claude Code skills

Canonical, cross-machine home for personal (user-level) Claude Code skills.
Cloned into `~/.claude/skills` on every machine so skills work in **all** projects.

## Skills
- `delegate-to-cli` — offload read-heavy local work (grep/read/comprehend, logs, translate, second-opinion) to a local AI CLI. Gemini CLI = verified backend; ChatGPT/Codex CLI = stub.
- `delegate-web-research` — manual copy-paste relay to any web-capable chat/agent (browser chat or agentic IDE) for live web / deep research.
- `new-branch` — create a git branch by personal naming pattern.

---

## Bootstrap on a NEW MACHINE (e.g. laptop)

The **skills** and the **backends** are two separate layers. Do both once per machine.

### 1. Get the skills (this repo)
```
git clone <this-repo-url> ~/.claude/skills
```
(If `~/.claude/skills` already exists, move it aside first.) Update later: `git pull`.

### 2. Install the local CLI backend (Gemini CLI)
```
npm install -g @google/gemini-cli          # needs Node 18+
setx GEMINI_API_KEY "<same key on every machine>"   # per-machine SECRET — never commit / never paste in chat
```
Then two per-machine files:
- `~/.gemini/settings.json` → `{ "security": { "auth": { "selectedType": "gemini-api-key" } } }`  (a leftover OAuth attempt otherwise overrides the key with IneligibleTierError)
- `~/.gemini/trustedFolders.json` → `{ "<your projects root, e.g. C:\\work>": "TRUST_FOLDER" }`  (one parent covers all repos under it; else `exit 55` "untrusted directory")

Verify: `gemini --version` then `gemini -m gemini-flash-latest -p "reply OK"`.

### 3. Grant the permission (optional but removes prompts)
Add to `~/.claude/settings.json` → `permissions.allow`: `"Bash(gemini:*)"`. (Otherwise Claude just asks each time — not broken.)

### 4. Web research needs NO install
`delegate-web-research` is a copy-paste relay — use any browser chat (ChatGPT / Gemini / Perplexity) or an agentic IDE (Antigravity) you already have. Nothing to install.

> **How you'll know what's missing:** you don't pre-decide. When a skill fires and a backend is absent, its Step-0 preflight detects it and Claude gives you the exact fix command (e.g. `npm install -g @google/gemini-cli`). See `delegate-to-cli` → "Setup on a new machine" for the full per-backend detail.

## New REPO on an already-set-up machine
Nothing to do — user-level skills + Gemini already apply. Only if the repo lives **outside** your trusted root, add its parent to `~/.gemini/trustedFolders.json`.

## Update everywhere
Edit here → `git commit` → `git push`; on other machines `git pull`.

## Not synced by git (per-machine)
The **API key**, `~/.gemini/*` (auth + trusted folders), and the `Bash(gemini:*)` permission in `~/.claude/settings.json` are machine-local by design (the key is a secret). Set them per step 2–3 above on each machine.
