---
name: scenario-design
description: Use BEFORE writing any code or implementation plan for a non-trivial feature. The skill teaches you to first elicit a set of numbered sequences (what the user/system does step by step) — split into LOGICAL ("what happens" in plain language, no functions, no types) and PROGRAMMATIC (which services/repos/jobs call each other, still no code). Cover happy path, negative paths, edge cases, adversarial, onboarding, maintenance, and observability categories. Invoke whenever the user asks for "последовательности", "сценарии", "design via sequences", or describes a feature without naming an implementation, or whenever you're about to commit to an architecture you can't easily undo. Also use for designing audits, retros, or post-incident "how it should have worked" walkthroughs.
---

# scenario-design

The biggest source of wasted code in a feature is **building the wrong thing
correctly**. Sequences expose disagreement about behaviour *before* anyone
writes a class. This skill is how you run that elicitation.

You are doing it right when:

- The user can read the sequences out loud to a stakeholder without
  pointing at any class name.
- Every step has exactly one verb and one outcome.
- Negative, edge, and adversarial sequences exist *next to* the happy
  path — not as an afterthought.
- The programmatic layer maps 1-to-1 to the logical layer and adds
  nothing new in terms of behaviour, only in terms of "which moving
  parts do this".

## When to invoke

Invoke this skill **before** building a plan or writing code when:

- the user describes a feature in business terms ("сделай чтобы X
  происходило при Y"), not in code terms,
- the user explicitly asks for "последовательности" / "сценарии" /
  "flows" / "user journeys",
- you're about to make a decision that's hard to reverse (new wire
  format, new public API, new background job lifecycle, a cron job
  that mutates third-party state),
- a feature involves more than two collaborators (e.g. cron + UI + MCP
  + external vendor) and someone might disagree about who owns what,
- the user asks "how would this work?" or "what would happen if…?",
- a post-incident walkthrough is needed and you want to capture
  "what should have happened" before "what did happen".

Do NOT invoke for tiny features (one-file edits, dependency bumps,
log-level tweaks). The overhead isn't worth it.

## The two layers

Every feature is described twice, in this order:

1. **Logical sequence** — what a human observer would say is happening.
   Verbs are real-world verbs: "the cron fires", "the admin saves the
   rule", "the patient slot is detected", "the system refuses". No
   class names, no method calls, no DTO names, no SQL. Anyone in the
   product team can read this.

2. **Programmatic sequence** — who calls whom. Names of services,
   repos, jobs, controllers, queues, external APIs. **Still no code.**
   This layer makes ownership explicit and surfaces missing seams
   ("wait, there's no observer to start the cleanup job after the
   admin saves").

Always write both. The logical layer is for the user / stakeholder
alignment. The programmatic layer is for you, future-you, and any
reviewer. They must be parallel: scenario N in the logical layer maps
to scenario N in the programmatic layer.

## Scenario categories — cover at least these

Don't stop at happy path. A complete design covers:

1. **Happy path** — the core thing the user wants. Usually the first
   sequence the user describes.

2. **Negative / failure modes** — what if a dependency is unavailable,
   times out, rejects the request, returns garbage? What if a slot is
   already taken? What if a rule's date window is empty? These are not
   "errors", they are *real branches of behaviour*.

3. **Edge cases** — empty inputs, the boundary day, the first/last
   tick, the slot exactly at midnight, the schedule with zero rules,
   the past. The category that bites you in production.

4. **Adversarial / concurrency** — two writers at once, race against
   the importer, the third-party system reporting state that
   contradicts our state, a stale read. "What if someone is mean to
   us / what if reality is."

5. **Onboarding / first-time** — first time a user enables the
   feature, fresh install, empty database. Often the same as edge but
   worth its own scenario because the *human* part matters
   (explanation, defaults, fallback messages).

6. **Maintenance / migration** — what does the upgrade look like?
   What happens during a roll-forward window when half the fleet is
   on the new behaviour? What happens to data created under the old
   rules?

7. **Observability** — how does the operator find out something went
   wrong? Which logs / metrics / audit trails are inspected? This
   sequence makes monitoring requirements concrete.

You don't have to write all seven for every feature. You do have to
*ask yourself* about all seven and consciously skip the ones that
don't apply, with a one-line reason.

## Scenario template

Each scenario is a section in a single `scenarios.md` (or
`<feature>-sequences.md`) document. Use this exact frame:

```markdown
## Scenario N — short imperative title

**What this checks**: one sentence on the property of the system being
demonstrated.

**Context**: state of the system right before the scenario begins
(who's logged in, what data exists, what config is set, what's running).

**Actors**: people, systems, queues, external services involved.

**Logical steps**:
1. Actor A does X.
2. System detects Y.
3. System decides Z.
4. ...

> *Mentor note*: why this branch is here / what would go wrong if we
> did it differently. One paragraph in italics.

**Programmatic steps**:
1. Entry point (controller / command / job / observer).
2. Repository / service / domain call.
3. External vendor / queue / cache hit.
4. ...

**What this closes**: list of user stories, tickets, requirements that
this scenario satisfies.

**Acceptance checklist**:
- [ ] One assertable behaviour per line.
- [ ] Written so a tester (or you in a month) can verify each.
- [ ] At least one item per test layer that applies (unit, feature,
      integration, manual).
```

The mentor note is mandatory for any scenario that's non-obvious or
controversial. It's where you record *why* a particular path was
chosen, so reviewers don't relitigate the decision.

## Workflow

1. **Elicit the happy path.** Ask the user to describe the main
   sequence in plain language. Write it down as the logical layer
   only. Don't talk about services yet.

2. **Read it back.** Confirm: is this what the feature does? Any
   missing actor, any silent step?

3. **Add the programmatic layer.** For each step, name the moving
   parts. Pause when a step needs a moving part that doesn't exist
   yet — that's a design decision to surface explicitly.

4. **Walk the seven categories.** For each, propose at least one
   scenario or say out loud why it doesn't apply. Examples to push
   on:
   - "What if the external system already has a record we don't know
     about?" → negative or adversarial.
   - "What about the first time this runs on an empty database?" →
     onboarding.
   - "How would on-call know it broke?" → observability.

5. **Confirm acceptance checklists.** Each scenario must produce at
   least one item the user/tester can sign off on. If you can't write
   the checklist, the scenario is too vague.

6. **Only then** convert into a plan / tickets / code. The
   `scenarios.md` becomes the spec the implementation answers.

## Where the document lives

- For a project with a `specs/<feature>/` layout (like the launcher
  repo), use `specs/<feature>/scenarios.md`.
- For a project with `docs/tasks/<year>/<month>/<id>_<slug>.md`
  (like eastclinic), embed the sequences as a top-level section of
  the task doc, OR put them in a sibling
  `docs/tasks/<…>/<id>_<slug>.scenarios.md`.
- For ad-hoc exploration with no repo yet, a single file at the
  project root is fine.

Whichever location: link to it from the PR description and from any
follow-up plan/ticket.

## Anti-patterns to refuse

- **Skipping the logical layer.** "It's a small feature, let me just
  describe the services." If you can't say what happens in human
  terms, the design isn't ready.
- **Smuggling implementation into the logical layer.** Step like "the
  controller calls the repository" is programmatic, not logical.
  Rewrite as "the system looks up the doctor's rules".
- **One sequence for everything.** If happy / failure / edge are mixed
  in the same numbered list with `if … then …`, split them.
- **No mentor note on a non-obvious choice.** Future readers will undo
  the decision because they don't see the reasoning.
- **Acceptance checklist that just paraphrases the steps.** A checklist
  item is *observable* (an HTTP response, a row in a table, a log
  line, a UI state) — not "step 4 executed correctly".

## Output to the user

After running the skill, end with:

- the path to the `scenarios.md`,
- a one-line per scenario summary so the user can skim,
- the categories you *skipped* with one-line reason each,
- an explicit ask: "review the sequences, then I'll convert to a
  plan / tickets / code".

Do not start writing the implementation until the user signs off on
the sequences.
