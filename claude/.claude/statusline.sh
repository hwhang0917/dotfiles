#!/usr/bin/env bash
# Claude Code statusline, lualine-flavoured: powerline sections for
# model · branch · context window · 5h/7d usage limits with reset countdowns.
# Input: statusline JSON on stdin. Requires jq and a Nerd Font.
set -uo pipefail

# Usage-percent thresholds that switch a gauge's colour.
WARN_PCT=50
CRIT_PCT=80

# Nerd Font glyphs — swap for ASCII here if a terminal lacks the font.
# Powerline range (U+E0B0-E0C8) ships in every Nerd Font, so these are safe.
G_BRANCH=''
G_MODEL='󰧑'
G_CLOCK='󰅐'
CAP_LEFT=''   # rounded head of the bar (U+E0B6)
CAP_RIGHT=''  # rounded tail of the bar (U+E0B4)
SEP_HARD=''   # between sections (U+E0B0)
SEP_SOFT=''   # within a section (U+E0B1)
# Gauge bar: same glyph throughout, colour alone marks the fill.
BAR_GLYPH='━'
BAR_CELLS=8
# Below these widths the bars shrink, then vanish, so the line never wraps.
WIDE_COLS=118
NARROW_COLS=100

# Breathing room: padding inside each section, gap around inner dividers.
PAD='  '
GAP='  '

# lualine-ish section palette (256-colour indices)
BG_A=110; FG_A=235   # section a — model, the "mode" slot; bg swaps per model family
# Model family → section-a background. Keyed by the display name's first word,
# lowercased, so "Opus 5" and "Opus 4.8" both land on opus. Unknown → BG_A.
declare -A MODEL_BG=(
  [fable]=222   # gold — the flagship
  [opus]=176    # orchid
  [sonnet]=110  # blue
  [haiku]=114   # green
)
BG_B=238; FG_B=252   # section b — branch
BG_C=236; FG_C=245   # section c — gauges
BG_Z=108; FG_Z=235   # section z — ponytail badge
BG_FILL=234          # elastic filler that stretches to the terminal edge
FG_OK=114; FG_WARN=215; FG_CRIT=204
FG_BAR_EMPTY=240     # unfilled part of a gauge bar

# Columns a pictographic Nerd Font glyph occupies. Nerd Font *Mono* variants
# render them single-width; the proportional variants draw them double. Ghostty
# here uses Mono, wezterm does not — bump to 2 if the bar overshoots the edge.
GLYPH_COLS=${CLAUDE_STATUSLINE_GLYPH_COLS:-1}
# Placeholder marking where the elastic section goes; never appears in output.
STRETCH=$'\001'

# Columns to leave free at the right edge. Claude Code renders the statusline in
# an Ink <Text wrap="truncate">, so one column of overshoot clips the tail with
# an ellipsis ("ponyta…"). The box is narrower than the terminal by the
# fullscreen frame's border and padding, and that cost isn't reported anywhere —
# hence a margin. Lower it to sit flusher right; raise it if the tail still cuts.
RIGHT_MARGIN=${CLAUDE_STATUSLINE_MARGIN:-4}

json=$(cat)
[ -n "${CLAUDE_STATUSLINE_DEBUG:-}" ] && printf '%s\n' "$json" >>"${TMPDIR:-/tmp}/claude-statusline.json"

IFS=$'\t' read -r cwd model ctx_pct h5_pct h5_reset d7_pct d7_reset wt_branch <<<"$(
  printf '%s' "$json" | jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // "?"),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.worktree.branch // "")
  ] | @tsv'
)"

# Drop the rate-limit gauges where session-less consumers (waybar, zebar) can
# read them; they recompute the countdowns from the raw reset epochs. "ts"
# lets consumers with several caches (WSL + native Windows) pick the freshest.
if [ -n "$h5_pct" ]; then
  printf '{"h5_pct":%s,"h5_reset":%s,"d7_pct":%s,"d7_reset":%s,"ts":%s}\n' \
    "$h5_pct" "${h5_reset:-null}" "${d7_pct:-null}" "${d7_reset:-null}" "$(date +%s)" \
    >"${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage.json"
fi

# Terminal width. A statusline hook has no tty on stdout, so borrow the TUI's:
# /dev/tty first, else the parent claude process's own stdout. Empty when
# undeterminable — callers then skip stretching rather than guess and wrap.
term_cols() {
  [ -n "${CLAUDE_STATUSLINE_COLS:-}" ] && { printf '%s' "$CLAUDE_STATUSLINE_COLS"; return; }
  local c src
  for src in /dev/tty "/proc/$PPID/fd/1" "/proc/$PPID/fd/2"; do
    # Group the redirect so bash's own "no such device" gripe is swallowed too.
    c=$( { stty size <"$src" | cut -d' ' -f2; } 2>/dev/null ) || continue
    [ -n "$c" ] && [ "$c" -gt 0 ] 2>/dev/null && { printf '%s' "$c"; return; }
  done
  printf '%s' "${COLUMNS:-}"
}

# Printable columns of a rendered string: drop SGR escapes, count characters,
# then re-add the extra column each wide glyph really takes.
visible_cols() {
  local g stripped plain
  plain=$(printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g')
  local n=${#plain}
  for g in "$G_MODEL" "$G_CLOCK" "$G_BRANCH"; do
    stripped=${plain//"$g"/}
    n=$(( n + (${#plain} - ${#stripped}) * (GLYPH_COLS - 1) ))
  done
  printf '%s' "$n"
}

branch() {
  [ -n "$wt_branch" ] && { printf '%s' "$wt_branch"; return; }
  [ -n "$cwd" ] || return
  # --no-optional-locks: this runs on a timer, so never contend for index.lock.
  git --no-optional-locks -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null && return
  git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null
}

fg_for() { # $1 = integer percent
  if [ "$1" -ge "$CRIT_PCT" ]; then printf '%s' "$FG_CRIT"
  elif [ "$1" -ge "$WARN_PCT" ]; then printf '%s' "$FG_WARN"
  else printf '%s' "$FG_OK"; fi
}

bar() { # $1 = integer percent, $2 = fill colour -> colour-filled bar
  # Round to nearest cell so a non-zero percent never renders as an empty bar.
  local filled=$(( ($1 * BAR_CELLS + 50) / 100 )) i
  [ "$filled" -gt "$BAR_CELLS" ] && filled=$BAR_CELLS
  [ "$filled" -eq 0 ] && [ "$1" -gt 0 ] && filled=1
  printf '\033[38;5;%sm' "$2"
  for ((i = 0; i < BAR_CELLS; i++)); do
    [ "$i" -eq "$filled" ] && printf '\033[38;5;%sm' "$FG_BAR_EMPTY"
    printf '%s' "$BAR_GLYPH"
  done
}

countdown() { # $1 = unix seconds -> "3h13m" / "2d4h" / "now"
  local left=$(( $1 - $(date +%s) ))
  [ "$left" -le 0 ] && { printf 'now'; return; }
  local d=$(( left / 86400 )) h=$(( left % 86400 / 3600 )) m=$(( left % 3600 / 60 ))
  if [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

gauge() { # $1 = label, $2 = percent (may be float/empty), $3 = optional resets_at
  [ -n "$2" ] || return
  local pct fg barstr=''
  pct=$(printf '%.0f' "$2")
  fg=$(fg_for "$pct")
  [ "$BAR_CELLS" -gt 0 ] && barstr="$(bar "$pct" "$fg") "
  printf '\033[38;5;%sm%s %s\033[38;5;%sm%d%%' "$FG_C" "$1" "$barstr" "$fg" "$pct"
  [ -n "$3" ] && printf '%s\033[38;5;%sm%s %s' "$GAP" "$FG_C" "$G_CLOCK" "$(countdown "$3")"
}

# Read the width up front: it decides how much gauge detail fits, and a resize
# is picked up on the next repaint since every render re-reads it.
cols=$(term_cols)
avail=''
if [ -n "$cols" ]; then
  avail=$(( cols - RIGHT_MARGIN ))
  [ "$avail" -lt 1 ] && avail=1
  if [ "$avail" -lt "$NARROW_COLS" ]; then
    BAR_CELLS=0
    PAD=' '; GAP=' '   # claw back the breathing room rather than wrap
  elif [ "$avail" -lt "$WIDE_COLS" ]; then
    BAR_CELLS=4
  fi
fi

# Section accumulators, rendered together so each knows its neighbour's background.
BGS=(); FGS=(); TXTS=(); PADS=()
section() { BGS+=("$1"); FGS+=("$2"); TXTS+=("$3"); PADS+=("${4-$PAD}"); }

fam=${model%% *}; fam=${fam,,}
section "${MODEL_BG[$fam]:-$BG_A}" "$FG_A" "${G_MODEL} ${model}"

b=$(branch)
[ -n "$b" ] && section "$BG_B" "$FG_B" "${G_BRANCH} ${b}"

soft=$'\033[38;5;'"${FG_C}m${GAP}${SEP_SOFT}${GAP}"
gauges=''
for g in "$(gauge ctx "$ctx_pct" '')" \
         "$(gauge 5h "$h5_pct" "$h5_reset")" \
         "$(gauge 7d "$d7_pct" "$d7_reset")"; do
  [ -n "$g" ] || continue
  [ -n "$gauges" ] && gauges+="$soft"
  gauges+="$g"
done
[ -n "$gauges" ] && section "$BG_C" "$FG_C" "$gauges"

# Elastic section: absorbs the leftover width so what follows sits flush right.
section "$BG_FILL" "$BG_FILL" "$STRETCH" ''

# ponytail mode badge, if the plugin flag is set
flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.ponytail-active"
if [ -f "$flag" ]; then
  mode=$(head -n1 "$flag" | tr -d '[:space:]')
  [ -z "$mode" ] && mode=full
  [ "$mode" = full ] && badge=ponytail || badge="ponytail:$mode"
  section "$BG_Z" "$FG_Z" "$badge"
fi

out=$(printf '\033[38;5;%sm%s' "${BGS[0]}" "$CAP_LEFT")
for i in "${!BGS[@]}"; do
  out+=$(printf '\033[48;5;%sm\033[38;5;%sm%s%s%s' \
    "${BGS[i]}" "${FGS[i]}" "${PADS[i]}" "${TXTS[i]}" "${PADS[i]}")
  next=${BGS[i+1]:-}
  if [ -n "$next" ]; then
    out+=$(printf '\033[48;5;%sm\033[38;5;%sm%s' "$next" "${BGS[i]}" "$SEP_HARD")
  else
    out+=$(printf '\033[0m\033[38;5;%sm%s\033[0m' "${BGS[i]}" "$CAP_RIGHT")
  fi
done

# Grow the elastic section to fill the terminal, stopping short of the margin.
if [ -n "$avail" ]; then
  used=$(visible_cols "${out/$STRETCH/}")
  fill=$(( avail - used ))
  [ "$fill" -lt 0 ] && fill=0
  printf -v spaces '%*s' "$fill" ''
  out=${out/$STRETCH/$spaces}
else
  out=${out/$STRETCH/}
fi
printf '%s' "$out"
