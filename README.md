# Personal Claude Code skills

Canonical, cross-machine home for personal (user-level) Claude Code skills.
Cloned into `~/.claude/skills` on every machine so skills work in **all** projects.

## Skills
- `delegate-to-agent` — offload read-heavy local work (grep/read/comprehend, logs, translate, second-opinion) to another agent. ONE channel: Antigravity paste-relay (no quota, repo-access). Local AI CLIs are retired.
- `delegate-web-research` — manual copy-paste relay to Antigravity for live web / deep research; carries the audit rules for what a research run returns.
- `model-routing` — keep session cost down **inside** Claude: delegate reading to subagents by default (closed list of exceptions), how to slice subagents short, which phase runs on which main-session model, and when to propose `/clear` vs `/compact`. No external CLI involved — the in-session counterpart to `delegate-to-agent`.
- `new-branch` — create a git branch, repo convention first, personal naming pattern as fallback.
- `scenario-design` — elicit numbered logical + programmatic sequences before any code or implementation plan.

---

## Bootstrap on a NEW MACHINE (e.g. laptop)

One step — clone this repo. There is no backend layer to set up any more (see step 2).

### 1. Get the skills (this repo)
```
git clone <this-repo-url> ~/.claude/skills
```
(If `~/.claude/skills` already exists, move it aside first.) Update later: `git pull`.

### 2. Backend: nothing to install
Both delegation skills are **paste-relays through Antigravity** — Claude prints a brief, you paste it there, you paste the result back. No CLI, no API key, no quota.

Local AI CLIs (Gemini CLI, codex) are **retired**: the free-tier web search 429s, and the 20-requests/day cap made the channel unreliable. Do not reinstate them without re-reading `delegate-to-agent`.

## New REPO on an already-set-up machine
Nothing to do — user-level skills apply everywhere.

## Update everywhere
Edit here → `git commit` → `git push`; on other machines `git pull`.

## Not synced by git (per-machine)
`~/.claude/settings.json` — model, permissions, env, theme. Machine-local by design: it holds per-machine paths and may hold secrets. This repo carries **skills only**.

## Not in this repo by design
Skills tied to **one project** (its servers, its deploy, its domain conventions) live in that project's own `.claude/skills/`, not here. This repo is public and cross-project; project skills belong next to the project they describe.
