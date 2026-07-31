#!/usr/bin/env bash
# Waybar module: Claude Code 5h/7d rate-limit gauges with reset countdowns.
# Reads the cache dropped by ~/.claude/statusline.sh on every statusline
# render; before the first Claude session there is no cache and the module
# stays hidden. Requires jq and a Nerd Font.
set -uo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage.json"

# Same thresholds as the statusline, mapped to CSS classes instead of colours.
WARN_PCT=50
CRIT_PCT=80
BAR_CELLS=5

hide() { printf '{"text":""}\n'; exit 0; }
[ -s "$CACHE" ] || hide

IFS=$'\t' read -r h5 h5_reset d7 d7_reset <<<"$(
  jq -r '[(.h5_pct // ""), (.h5_reset // ""), (.d7_pct // ""), (.d7_reset // "")] | @tsv' \
    "$CACHE" 2>/dev/null
)"
[ -n "$h5" ] || hide

bar() { # $1 = integer percent -> ▰▰▰▱▱
  # Round to nearest cell so a non-zero percent never renders as an empty bar.
  local filled=$(( ($1 * BAR_CELLS + 50) / 100 )) i out=''
  [ "$filled" -gt "$BAR_CELLS" ] && filled=$BAR_CELLS
  [ "$filled" -eq 0 ] && [ "$1" -gt 0 ] && filled=1
  for ((i = 0; i < BAR_CELLS; i++)); do
    [ "$i" -lt "$filled" ] && out+='▰' || out+='▱'
  done
  printf '%s' "$out"
}

countdown() { # $1 = unix seconds -> "3h13m" / "2d4h" / "now"
  local left=$(( ${1%.*} - $(date +%s) ))
  [ "$left" -le 0 ] && { printf 'now'; return; }
  local d=$(( left / 86400 )) h=$(( left % 86400 / 3600 )) m=$(( left % 3600 / 60 ))
  if [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

gauge() { # $1 = label, $2 = percent, $3 = resets_at epoch ("null" when absent)
  local pct
  pct=$(printf '%.0f' "$2")
  printf '%s %s %d%%' "$1" "$(bar "$pct")" "$pct"
  [ "$3" != null ] && [ -n "$3" ] && printf ' 󰅐 %s' "$(countdown "$3")"
}

p5=$(printf '%.0f' "$h5")
p7=$(printf '%.0f' "${d7:-0}")
worst=$p5
[ "$p7" -gt "$worst" ] && worst=$p7
class=ok
if [ "$worst" -ge "$CRIT_PCT" ]; then class=critical
elif [ "$worst" -ge "$WARN_PCT" ]; then class=warning; fi

text="󰧑 $(gauge 5h "$h5" "$h5_reset")"
[ -n "$d7" ] && text+="  $(gauge 7d "$d7" "$d7_reset")"

tooltip="Claude usage (from last statusline update)"
tooltip+=$'\n'"5h: ${p5}% — resets $( [ "$h5_reset" != null ] && date -d "@${h5_reset%.*}" '+%a %H:%M' || echo '?' )"
[ -n "$d7" ] && tooltip+=$'\n'"7d: ${p7}% — resets $( [ "$d7_reset" != null ] && date -d "@${d7_reset%.*}" '+%a %d %b %H:%M' || echo '?' )"

jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
