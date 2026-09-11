#!/usr/bin/env bash
# daily-recap — сборщик сырых фактов из git/GitHub за период.
#
#   recap.sh window                          печатает SINCE/UNTIL по умолчанию: вчера 10:00 .. сейчас
#   recap.sh collect <repo-path> <since> <until>
#                                            сырые факты по одному репозиторию
#
# Даты — локальные, формат YYYY-MM-DDTHH:MM:SS. Скрипт ничего не меняет в репозиториях
# (только `git fetch`) и никакого состояния между вызовами не хранит.
set -u

cmd_window() {
  echo "SINCE=$(date -d "yesterday 10:00" "+%Y-%m-%dT%H:%M:%S")"
  echo "UNTIL=$(date "+%Y-%m-%dT%H:%M:%S")"
}

cmd_collect() {
  local repo="$1" since="$2" until="$3"
  if [ ! -e "$repo/.git" ]; then
    echo "!! $repo — не git-репозиторий или путь не существует"
    return 1
  fi
  cd "$repo" || return 1

  local me; me=$(git config user.name)
  echo "=================================================================="
  echo "=== REPO $(basename "$repo")   $(git remote get-url origin 2>/dev/null)"
  echo "=== period $since .. $until   me=$me"
  echo "=================================================================="

  if ! git fetch --all --prune --quiet 2>/dev/null; then
    echo "(!) git fetch не удался — удалённые ветки могут быть устаревшими"
  fi

  echo
  echo "--- текущая ветка: $(git rev-parse --abbrev-ref HEAD)"
  echo "--- незакоммиченные правки (состояние на сейчас, без даты):"
  git status --porcelain | head -40
  [ -z "$(git status --porcelain)" ] && echo "(чисто)"
  echo "--- stash:"
  git stash list | head -10
  [ -z "$(git stash list)" ] && echo "(нет)"

  echo
  echo "--- ветки, на которых были коммиты в период (локальные и удалённые):"
  git for-each-ref --sort=-committerdate refs/heads refs/remotes \
      --format='%(committerdate:iso-local)  %(refname:short)  [%(authorname)]' 2>/dev/null \
    | awk -v s="$since" -v u="$until" '{ d=$1"T"$2; if (d>=s && d<=u) print }'

  echo
  echo "--- коммиты в период (все ветки, новые сверху; ветки, где лежит коммит — в строке ->):"
  local sha
  for sha in $(git log --all --since="$since" --until="$until" --format=%h); do
    if [ "$(git rev-list --parents -n 1 "$sha" | wc -w)" -gt 2 ]; then
      git log -1 --date=iso-local --format='%n### %h  %ad  %an  (MERGE — сама работа в коммитах ветки)%n%s' "$sha"
    else
      git log -1 --date=iso-local --format='%n### %h  %ad  %an%n%s%n%b' "$sha" | sed '/^$/N;/^\n$/D'
    fi
    echo "  -> $(git branch -a --contains "$sha" --format='%(refname:short)' 2>/dev/null | grep -v 'HEAD' | head -6 | paste -sd ',' -)"
    git show --stat=100,60,30 --format= "$sha" 2>/dev/null | sed 's/^/     /'
  done

  echo
  echo "--- незапушенная работа: локальные ветки с коммитами в период, которых нет ни на одной удалённой ветке:"
  local br n
  for br in $(git for-each-ref --sort=-committerdate refs/heads --format='%(refname:short)'); do
    git for-each-ref "refs/heads/$br" --format='%(committerdate:iso-local)'       | awk -v s="$since" -v u="$until" '{ d=$1"T"$2; exit !(d>=s && d<=u) }' || continue
    n=$(git log "$br" --not --remotes --format=%h 2>/dev/null | wc -l | tr -d ' ')
    if [ "$n" -gt 0 ]; then
      echo "  $br — $n коммит(ов) только локально:"
      git log "$br" --not --remotes --date=iso-local --format='     %h  %ad  %s' 2>/dev/null | head -10
    fi
  done

  echo
  echo "--- планы и документы, тронутые в период (коммиты + незакоммиченное); [x]/[ ] — сделано/не сделано:"
  local f
  { git log --all --since="$since" --until="$until" --name-only --format= 2>/dev/null
    git status --porcelain | awk '{print $NF}'
  } | grep -iE '(^|/)(docs?|plans?|tasks?)/.*\.md$|(plan|handoff|todo|roadmap|checklist)[^/]*\.md$'     | grep -viE '^docs/(api|arch|runbooks)/|README\.md$' | sort -u | while read -r f; do
      [ -f "$f" ] || { echo "  $f (удалён)"; continue; }
      echo "  $f  — чекбоксы: сделано $(grep -cE '^\s*[-*] \[[xX]\]' "$f"), не сделано $(grep -cE '^\s*[-*] \[ \]' "$f"); строк $(wc -l < "$f")"
      echo "     оглавление (пункты плана сверять с коммитами и PR выше):"
      grep -nE '^#{1,3} ' "$f" | head -40 | sed 's/^/       /'
      grep -nE '^\s*[-*] \[ \]' "$f" | head -15 | sed 's/^/       /'
    done

  if command -v gh >/dev/null 2>&1; then
    local nwo since_utc
    nwo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
    since_utc=$(date -u -d "$since" "+%Y-%m-%dT%H:%M:%SZ")
    echo
    echo "--- pull requests, менявшиеся в период ($nwo; время в UTC):"
    # search-API GitHub у части организаций закрыт (любой --search тихо даёт пусто),
    # поэтому берём последние 60 PR и фильтруем по updatedAt сами.
    SINCE_UTC="$since_utc" gh pr list --state all --limit 60 \
      --json number,title,state,author,headRefName,baseRefName,createdAt,updatedAt,mergedAt,url \
      --jq 'map(select(.updatedAt >= env.SINCE_UTC)) | .[]
            | "#\(.number) [\(.state)] \(.title)\n     \(.headRefName) -> \(.baseRefName)   by \(.author.login)   created \(.createdAt)   merged \(.mergedAt // "-")   updated \(.updatedAt)\n     \(.url)"' \
      2>&1 | head -80
  else
    echo "(gh не установлен — pull requests не собраны)"
  fi
  echo
}

case "${1:-}" in
  window)  cmd_window ;;
  collect) shift; cmd_collect "$@" ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
