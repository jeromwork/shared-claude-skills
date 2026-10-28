export type Limit = { kind: string; percentUsed: number; resetsAt?: string }

export type TurnStat = {
  seconds: number
  // прирост процента по окнам: kind → +%
  claude: Record<string, number>
  codex: Record<string, number>
  skills: string[]
  agents: number
  codexRuns: number
}

declare module 'claude-code' {
  interface PluginState {
    'limits-band': {
      claude: Limit[]
      codex: Limit[] | null
      codexError: string | null
      last: TurnStat | null
      isHidden: boolean
    }
  }
}
