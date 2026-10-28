#!/usr/bin/env node
// Проценты лимита Codex без траты лимита: спрашивает codex app-server
// (account/rateLimits/read) и печатает одну строку JSON:
//   {"ok":true,"plan":"prolite","windows":[{"kind":"week","percentUsed":3,"resetsAt":"2026-11-04T..."}]}
// При ошибке: {"ok":false,"error":"..."} и код выхода 1.
import { spawn } from 'node:child_process'

const windowKind = mins => (mins === 300 ? '5h' : mins === 10080 ? 'week' : `${mins}m`)

const child = spawn('codex app-server', { shell: true, stdio: ['pipe', 'pipe', 'ignore'] })
let buf = ''
const finish = (out, code) => {
  process.stdout.write(JSON.stringify(out) + '\n')
  child.kill()
  process.exit(code)
}
const timer = setTimeout(() => finish({ ok: false, error: 'codex app-server не ответил за 20 с' }, 1), 20000)

child.stdout.on('data', chunk => {
  buf += chunk
  let nl
  while ((nl = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, nl)
    buf = buf.slice(nl + 1)
    let msg
    try { msg = JSON.parse(line) } catch { continue }
    if (msg.id !== 2) continue
    clearTimeout(timer)
    if (msg.error) finish({ ok: false, error: msg.error.message ?? String(msg.error) }, 1)
    const rl = msg.result?.rateLimits ?? {}
    const windows = [rl.primary, rl.secondary].filter(Boolean).map(w => ({
      kind: windowKind(w.windowDurationMins),
      percentUsed: w.usedPercent,
      resetsAt: w.resetsAt ? new Date(w.resetsAt * 1000).toISOString() : undefined,
    }))
    finish({ ok: true, plan: rl.planType ?? null, reached: rl.rateLimitReachedType ?? null, windows }, 0)
  }
})
child.on('error', err => finish({ ok: false, error: err.message }, 1))

const send = o => child.stdin.write(JSON.stringify(o) + '\n')
send({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { clientInfo: { name: 'codex-limits', version: '0.1' } } })
send({ jsonrpc: '2.0', method: 'initialized' })
send({ jsonrpc: '2.0', id: 2, method: 'account/rateLimits/read' })
