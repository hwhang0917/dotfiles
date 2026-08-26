# Claude Code statusline for native Windows (PowerShell). Core companion to
# statusline.sh: model - branch - ctx/5h/7d usage gauges as coloured text.
# Skips the powerline separators, width elasticity, and ponytail badge that the
# bash version carries. Input: statusline JSON on stdin. No jq needed.
$ErrorActionPreference = 'Stop'

# Usage-percent thresholds that switch a gauge's colour.
$WARN_PCT = 50
$CRIT_PCT = 80

$ESC = [char]27
function Fg([int]$c) { "$ESC[38;5;${c}m" }
$RESET = "$ESC[0m"
$FG_OK = 114; $FG_WARN = 215; $FG_CRIT = 204
$FG_BRANCH = 252; $FG_LABEL = 245; $FG_SEP = 240

# Model family -> foreground colour, keyed by the display name's first word
# lowercased so "Opus 5" and "Opus 4.8" both land on opus. Mirrors statusline.sh.
$MODEL_FG = @{ fable = 222; opus = 176; sonnet = 110; haiku = 114 }

$data = [Console]::In.ReadToEnd() | ConvertFrom-Json

# Drop the rate-limit gauges where session-less consumers (zebar) can read
# them. Mirrors statusline.sh's cache; "ts" lets consumers with several caches
# (WSL + native Windows) pick the freshest.
$h5 = $data.rate_limits.five_hour
if ($null -ne $h5.used_percentage) {
  $cacheDir = Join-Path $HOME '.cache'
  New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
  @{
    h5_pct   = $h5.used_percentage
    h5_reset = $h5.resets_at
    d7_pct   = $data.rate_limits.seven_day.used_percentage
    d7_reset = $data.rate_limits.seven_day.resets_at
    ts       = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
  } | ConvertTo-Json -Compress | Set-Content -Path (Join-Path $cacheDir 'claude-usage.json') -NoNewline
}

$model = if ($data.model.display_name) { $data.model.display_name } else { '?' }
$cwd = if ($data.workspace.current_dir) { $data.workspace.current_dir } else { $data.cwd }

function FgFor([int]$pct) {
  if ($pct -ge $CRIT_PCT) { $FG_CRIT }
  elseif ($pct -ge $WARN_PCT) { $FG_WARN }
  else { $FG_OK }
}

# Unix-epoch reset time -> "3h13m" / "2d4h" / "now". Empty on missing/bad input.
# Matches statusline.sh, which treats resets_at as epoch seconds.
function Countdown($resetsAt) {
  if (-not $resetsAt) { return '' }
  try { $left = [int64]$resetsAt - [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
  catch { return '' }
  if ($left -le 0) { return 'now' }
  $d = [math]::Floor($left / 86400); $h = [math]::Floor(($left % 86400) / 3600)
  $m = [math]::Floor(($left % 3600) / 60)
  if ($d -gt 0) { return '{0}d{1}h' -f $d, $h }
  if ($h -gt 0) { return '{0}h{1}m' -f $h, $m }
  return '{0}m' -f $m
}

function Gauge($label, $pct, $resetsAt) {
  if ($null -eq $pct -or $pct -eq '') { return '' }
  $p = [int][math]::Round([double]$pct)
  $s = "$(Fg $FG_LABEL)$label $(Fg (FgFor $p))$p%"
  $cd = Countdown $resetsAt
  if ($cd) { $s += "$(Fg $FG_LABEL) $cd" }
  return $s
}

# Prefer the worktree branch Claude reports; else ask git. --no-optional-locks:
# this runs on a timer, so never contend for index.lock.
function GitBranch($dir) {
  if ($data.worktree.branch) { return $data.worktree.branch }
  if (-not $dir) { return '' }
  $b = git --no-optional-locks -C $dir symbolic-ref --quiet --short HEAD 2>$null
  if ($b) { return $b }
  return git --no-optional-locks -C $dir rev-parse --short HEAD 2>$null
}

$fam = ($model -split ' ')[0].ToLower()
$modelFg = if ($MODEL_FG.ContainsKey($fam)) { $MODEL_FG[$fam] } else { 176 }

$parts = @("$(Fg $modelFg)$model")
$b = GitBranch $cwd
if ($b) { $parts += "$(Fg $FG_BRANCH)$b" }

$gauges = @(
  (Gauge 'ctx' $data.context_window.used_percentage $null),
  (Gauge '5h' $data.rate_limits.five_hour.used_percentage $data.rate_limits.five_hour.resets_at),
  (Gauge '7d' $data.rate_limits.seven_day.used_percentage $data.rate_limits.seven_day.resets_at)
) | Where-Object { $_ }
if ($gauges) { $parts += ($gauges -join "$(Fg $FG_LABEL) ") }

$sep = "$(Fg $FG_SEP)  |  "
[Console]::Out.Write((($parts -join $sep) + $RESET))
