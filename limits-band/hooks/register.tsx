import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Limit, TurnStat } from '../types'

// Скрипт из shared-claude-skills (~/.claude/skills/codex/limits.mjs): спрашивает
// codex app-server, лимит не тратит. Домашний каталог узнаёт сам node — так мод
// не привязан к машине.
const CODEX_LIMITS_ARGV = [
  'node',
  '-e',
  "import(require('url').pathToFileURL(require('path').join(require('os').homedir(), '.claude/skills/codex/limits.mjs')))",
]
const CODEX_EVERY_MS = 5 * 60 * 1000

const claude = atom({ plugin: 'limits-band', key: 'claude' } as const, [] as Limit[])
const codex = atom({ plugin: 'limits-band', key: 'codex' } as const, null as Limit[] | null)
const codexError = atom({ plugin: 'limits-band', key: 'codexError' } as const, null as string | null)
const last = atom({ plugin: 'limits-band', key: 'last' } as const, null as TurnStat | null)
const isHidden = atom({ plugin: 'limits-band', key: 'isHidden' } as const, false)

const KIND: Record<string, string> = { five_hour: '5ч', seven_day: 'нед', '5h': '5ч', week: 'нед' }
const kindName = (k: string) => KIND[k] ?? k

const fmtLimits = (ls: Limit[]) => ls.map(l => `${kindName(l.kind)} ${l.percentUsed}%`).join(' · ')

const fmtReset = (iso?: string) => {
  if (!iso) return ''
  const d = new Date(iso)
  const p = (n: number) => String(n).padStart(2, '0')
  return `сброс ${p(d.getDate())}.${p(d.getMonth() + 1)} ${p(d.getHours())}:${p(d.getMinutes())}`
}

const fmtDuration = (s: number) => (s < 60 ? `${s} с` : `${Math.floor(s / 60)} мин ${s % 60} с`)

const delta = (before: Limit[] | null, after: Limit[] | null) => {
  const out: Record<string, number> = {}
  for (const a of after ?? []) {
    const b = (before ?? []).find(x => x.kind === a.kind)
    if (b) out[a.kind] = Math.round((a.percentUsed - b.percentUsed) * 10) / 10
  }
  return out
}

const fmtDelta = (d: Record<string, number>) =>
  Object.entries(d)
    .map(([k, v]) => `${kindName(k)} ${v >= 0 ? '+' : ''}${v}%`)
    .join(' ')

async function refreshCodex($: EngineInterface) {
  try {
    const r = await $.process.run(CODEX_LIMITS_ARGV, { timeoutMs: 30000 })
    const d = JSON.parse(r.stdout.trim().split('\n').pop() ?? '{}')
    if (d.ok) {
      await update($, codex, () => d.windows as Limit[])
      await update($, codexError, () => null)
    } else {
      await update($, codexError, () => String(d.error ?? 'нет ответа'))
    }
  } catch (err) {
    await update($, codexError, () => String(err))
  }
}

export const register: Register = on => {
  // начало главного хода: время и проценты, чтобы посчитать расход хода
  let turn: {
    startedAt: number
    claude: Limit[]
    codex: Limit[] | null
    skills: Set<string>
    agents: number
    codexRuns: number
  } | null = null

  on('session.start', async ($, e, next) => {
    const started = await next(e)
    const u = await $.session.usage()
    await update($, claude, () => u.rateLimits)
    void refreshCodex($)
    $.clock.every(CODEX_EVERY_MS, () => void refreshCodex($))
    await $.command.register({ name: 'limits', description: 'Показать или скрыть полосу лимитов Claude и Codex' })
    return started
  })

  on('command.run', { command: 'limits' }, async $ => {
    const hidden = await read($, isHidden)
    await update($, isHidden, () => !hidden)
    if (hidden) void refreshCodex($)
    return { text: hidden ? 'Полоса лимитов показана.' : 'Полоса лимитов скрыта.' }
  })

  on('session.measure', async ($, e, next) => {
    await update($, claude, () => e.rateLimits)
    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    if (!e.agentId) {
      turn = {
        startedAt: await $.clock.now(),
        claude: await read($, claude),
        codex: await read($, codex),
        skills: new Set(),
        agents: 0,
        codexRuns: 0,
      }
    }
    return next(e)
  })

  // только считает, вызов инструмента не задерживает и не роняет
  on('tool.call', ($, e, next) => {
    try {
      if (turn) {
        const input = (e as { input?: Record<string, unknown> }).input ?? {}
        if (e.tool === 'Skill' && typeof input.skill === 'string') turn.skills.add(input.skill)
        if (e.tool === 'Agent') turn.agents += 1
        if (e.tool === 'Bash' && typeof input.command === 'string' && /\bcodex\b/.test(input.command)) {
          turn.codexRuns += 1
        }
      }
    } catch {
      // счёт хода не важнее самого вызова
    }
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId || !turn) return result
    const t = turn
    turn = null
    if (t.codexRuns > 0) await refreshCodex($)
    const u = await $.session.usage()
    await update($, claude, () => u.rateLimits)
    const stat: TurnStat = {
      seconds: Math.round(((await $.clock.now()) - t.startedAt) / 1000),
      claude: delta(t.claude, u.rateLimits),
      codex: delta(t.codex, await read($, codex)),
      skills: [...t.skills],
      agents: t.agents,
      codexRuns: t.codexRuns,
    }
    await update($, last, () => stat)
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey || (await read($, isHidden))) return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)

    const cl = await read($, claude)
    const cx = await read($, codex)
    const cxErr = await read($, codexError)
    const t = await read($, last)

    const codexText = cx ? fmtLimits(cx) : cxErr ? '?' : '…'

    // одна строка: проценты, затем расход последнего хода
    const parts = [`Claude ${cl.length ? fmtLimits(cl) : '…'}`, `Codex ${codexText}`]
    if (t) {
      const spent = [fmtDelta(t.claude), t.codexRuns > 0 ? `Codex ${fmtDelta(t.codex) || '+0%'}` : '']
        .filter(Boolean)
        .join(' ')
      parts.push(`ход ${fmtDuration(t.seconds)}${spent ? ` ${spent}` : ''}`)
      if (t.skills.length) parts.push(t.skills.join(','))
    }

    return (
      <Box>
        <Text dimColor>{parts.join(' │ ')} </Text>
        <Button key="hide" label="×" onPress={() => update($, isHidden, () => true)} />
      </Box>
    )
  })
}
