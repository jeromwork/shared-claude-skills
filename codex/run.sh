#!/usr/bin/env bash
# Задание Codex без общего контекста: Codex видит только текст задания,
# Claude получает только итог. Ход работы Codex — в журнале, не в выводе.
#
#   run.sh <папка> <файл-задания> [усилие] [модель] [песочница]
#     усилие     — low (по умолчанию, так задумал OpenAI для Sol) | medium | high | xhigh
#     модель     — по умолчанию gpt-6.1-sol
#     песочница  — workspace-write (по умолчанию) | read-only | full (без песочницы)
#   run.sh --check   — доступен ли Codex: вход, тариф, проценты лимита (лимит не тратит)
#
# Пишет рядом с файлом задания: <имя>.log.jsonl (весь ход), <имя>.answer.md (итог).
# Печатает: итог Codex, время, токены, проценты лимита Codex до и после.
set -u
export PYTHONIOENCODING=utf-8
HERE=$(cd "$(dirname "$0")" && pwd)

limits() { node "$HERE/limits.mjs" 2>/dev/null | python -c "import json,sys
d=json.loads(sys.stdin.read() or '{}')
print(' · '.join(f\"{w['kind']} {w['percentUsed']}%\" for w in d.get('windows',[])) if d.get('ok') else 'нет данных: '+str(d.get('error')))"; }

if [ "${1:-}" = "--check" ]; then
  codex login status 2>&1 | head -1
  node "$HERE/limits.mjs"
  exit $?
fi

DIR=${1:?папка}; TASK=${2:?файл задания}; EFFORT=${3:-low}; MODEL=${4:-gpt-6.1-sol}; SANDBOX=${5:-workspace-write}
BASE=${TASK%.*}; LOG=$BASE.log.jsonl; ANSWER=$BASE.answer.md

case $SANDBOX in
  full) SB=(--dangerously-bypass-approvals-and-sandbox) ;;
  *)    SB=(-s "$SANDBOX") ;;
esac

# Субагенту не нужны свои агенты, браузер, управление экраном, память, плагины:
# каждый такой инструмент — лишнее описание во входе каждого запроса.
LEAN=(--disable multi_agent --disable apps --disable browser_use --disable browser_use_external
      --disable computer_use --disable goals --disable memories --disable plugins --disable image_generation)

BEFORE=$(limits)
START=$(date +%s)
codex exec --json --skip-git-repo-check --ephemeral -m "$MODEL" -c model_reasoning_effort="$EFFORT" \
  -C "$DIR" "${SB[@]}" "${LEAN[@]}" -o "$ANSWER" - < "$TASK" > "$LOG" 2>"$BASE.err"
RC=$?
SECS=$(( $(date +%s) - START ))
AFTER=$(limits)

TOKENS=$(python - "$LOG" <<'PY'
import json,sys
tot={}
for line in open(sys.argv[1],encoding='utf-8',errors='replace'):
    try: m=json.loads(line)
    except Exception: continue
    if m.get('type')=='turn.completed':
        for k,v in (m.get('usage') or {}).items(): tot[k]=tot.get(k,0)+v
print(f"вход {tot.get('input_tokens',0)} (из кэша {tot.get('cached_input_tokens',0)}), выход {tot.get('output_tokens',0)}" if tot else 'нет')
PY
)

echo "=== Codex ($MODEL, $EFFORT, $SANDBOX), код выхода $RC ==="
if [ -s "$ANSWER" ]; then cat "$ANSWER"; else echo "(итога нет — смотреть $BASE.err и $LOG)"; tail -5 "$BASE.err"; fi
echo
echo "=== время $((SECS/60)) мин $((SECS%60)) с · токены: $TOKENS"
echo "=== лимит Codex: до [$BEFORE] → после [$AFTER]"
echo "=== журнал: $LOG"
exit $RC
