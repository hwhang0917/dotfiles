import { useState, useEffect } from "react";
import * as zebar from "zebar";
import { getBatteryIcon, getWeatherIcon } from "./icons";
import "./styles.css";

// Claude Code 5h/7d rate-limit gauges, mirroring the waybar module. Reads the
// cache dropped by ~/.claude/statusline.{sh,ps1} on every statusline render;
// both the native Windows and WSL caches are polled and the freshest "ts"
// wins. Hidden until a first Claude session writes a cache.
const CLAUDE_POLL_MS = 60_000;
const CLAUDE_WARN_PCT = 50;
const CLAUDE_CRIT_PCT = 80;
const CLAUDE_BAR_CELLS = 5;
const CLAUDE_CACHE_READS: [string, string[]][] = [
  ["cmd", ["/c", "type", "%USERPROFILE%\\.cache\\claude-usage.json"]],
  ["wsl", ["-e", "sh", "-c", "cat ~/.cache/claude-usage.json"]],
];

type ClaudeUsage = {
  h5_pct: number;
  h5_reset: number | null;
  d7_pct: number | null;
  d7_reset: number | null;
  ts: number;
};

async function readClaudeUsage(): Promise<ClaudeUsage | null> {
  const reads = await Promise.all(
    CLAUDE_CACHE_READS.map(async ([program, args]) => {
      try {
        const { stdout } = await zebar.shellExec(program, args);
        return JSON.parse(stdout) as ClaudeUsage;
      } catch {
        return null;
      }
    }),
  );
  return (
    reads
      .filter((r): r is ClaudeUsage => r?.h5_pct != null)
      .sort((a, b) => (b.ts ?? 0) - (a.ts ?? 0))[0] ?? null
  );
}

function usageBar(pct: number): string {
  // Round to nearest cell so a non-zero percent never renders as an empty bar.
  let filled = Math.round((pct * CLAUDE_BAR_CELLS) / 100);
  if (filled === 0 && pct > 0) filled = 1;
  filled = Math.min(filled, CLAUDE_BAR_CELLS);
  return "█".repeat(filled) + "░".repeat(CLAUDE_BAR_CELLS - filled);
}

function resetCountdown(resetsAt: number | null): string {
  if (resetsAt == null) return "";
  const left = Math.floor(resetsAt - Date.now() / 1000);
  if (left <= 0) return "now";
  const d = Math.floor(left / 86400);
  const h = Math.floor((left % 86400) / 3600);
  const m = Math.floor((left % 3600) / 60);
  return d > 0 ? `${d}d${h}h` : h > 0 ? `${h}h${m}m` : `${m}m`;
}

const providers = zebar.createProviderGroup({
  glazewm: { type: "glazewm" },
  cpu: { type: "cpu" },
  date: { type: "date", formatting: "DDDD tt", refreshInterval: 1000 },
  battery: { type: "battery" },
  memory: { type: "memory" },
  weather: { type: "weather" },
});

export default function App() {
  const [output, setOutput] = useState(providers.outputMap);
  const [claude, setClaude] = useState<ClaudeUsage | null>(null);

  useEffect(() => {
    providers.onOutput(() => setOutput(providers.outputMap));
  }, []);

  useEffect(() => {
    const poll = () => readClaudeUsage().then(setClaude);
    poll();
    const id = setInterval(poll, CLAUDE_POLL_MS);
    return () => clearInterval(id);
  }, []);

  const glazewm = output.glazewm;
  const cpu = output.cpu;
  const battery = output.battery;
  const memory = output.memory;
  const weather = output.weather;

  const p5 = claude ? Math.round(claude.h5_pct) : 0;
  const p7 = claude?.d7_pct != null ? Math.round(claude.d7_pct) : null;
  const worst = Math.max(p5, p7 ?? 0);
  const claudeClass =
    worst >= CLAUDE_CRIT_PCT
      ? "critical"
      : worst >= CLAUDE_WARN_PCT
        ? "warning"
        : "ok";
  const resetStamp = (t: number | null) =>
    t == null
      ? "?"
      : new Date(t * 1000).toLocaleString([], {
          weekday: "short",
          day: "2-digit",
          month: "short",
          hour: "2-digit",
          minute: "2-digit",
        });


  return (
    <div className="app">
      <div className="left">
        <i className="logo nf nf-custom-windows" />
        {glazewm && (
          <div className="workspaces">
            {glazewm.currentWorkspaces.map((workspace) => (
              <button
                className={`workspace ${workspace.hasFocus && "focused"} ${workspace.isDisplayed && "displayed"}`}
                onClick={() =>
                  glazewm.runCommand(
                    `focus --workspace ${workspace.name}`,
                  )
                }
                key={workspace.name}
              >
                {workspace.displayName ?? workspace.name}
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="center">{output.date?.formatted}</div>

      <div className="right">
        {glazewm && (
          <>
            {glazewm.isPaused && (
              <button
                className="paused-button"
                onClick={() =>
                  glazewm.runCommand("wm-toggle-pause")
                }
              >
                PAUSED
              </button>
            )}
            {glazewm.bindingModes.map((bindingMode) => (
              <button
                className="binding-mode"
                key={bindingMode.name}
                onClick={() =>
                  glazewm.runCommand(
                    `wm-disable-binding-mode --name ${bindingMode.name}`,
                  )
                }
              >
                {bindingMode.displayName ?? bindingMode.name}
              </button>
            ))}
            <button
              className={`tiling-direction nf ${glazewm.tilingDirection === "horizontal" ? "nf-md-swap_horizontal" : "nf-md-swap_vertical"}`}
              onClick={() =>
                glazewm.runCommand("toggle-tiling-direction")
              }
            />
          </>
        )}

        {claude && (
          <div
            className={`claude-usage ${claudeClass}`}
            title={
              `Claude usage (from last statusline update)` +
              `\n5h: ${p5}% — resets ${resetStamp(claude.h5_reset)}` +
              (p7 != null
                ? `\n7d: ${p7}% — resets ${resetStamp(claude.d7_reset)}`
                : "")
            }
          >
            <i className="nf nf-md-brain" />
            <span>
              5h {usageBar(p5)} {p5}%
            </span>
            {claude.h5_reset != null && (
              <span className="reset">
                <i className="nf nf-md-clock_outline" />
                {resetCountdown(claude.h5_reset)}
              </span>
            )}
            {p7 != null && (
              <>
                <span className="divider">│</span>
                <span>
                  7d {usageBar(p7)} {p7}%
                </span>
                {claude.d7_reset != null && (
                  <span className="reset">
                    <i className="nf nf-md-clock_outline" />
                    {resetCountdown(claude.d7_reset)}
                  </span>
                )}
              </>
            )}
          </div>
        )}

        {memory && (
          <div
            className="memory"
            title={`RAM: ${(memory.usedMemory / 1e9).toFixed(1)} / ${(memory.totalMemory / 1e9).toFixed(1)} GB`}
          >
            <i className="nf nf-fae-chip" />
            {Math.round(memory.usage)}%
          </div>
        )}

        {cpu && (
          <div
            className="cpu"
            title={`CPU: ${cpu.vendor} | ${cpu.physicalCoreCount} cores / ${cpu.logicalCoreCount} threads | ${(cpu.frequency / 1e3).toFixed(2)} GHz`}
          >
            <i className="nf nf-oct-cpu" />
            <span className={cpu.usage > 85 ? "high-usage" : ""}>
              {Math.round(cpu.usage)}%
            </span>
          </div>
        )}

        {battery && (
          <div
            className="battery"
            title={`Battery: ${battery.state} | Health: ${Math.round(battery.healthPercent)}% | Cycles: ${battery.cycleCount}${battery.timeTillEmpty != null ? ` | ${Math.round(battery.timeTillEmpty / 60)} min remaining` : ""}${battery.timeTillFull != null ? ` | ${Math.round(battery.timeTillFull / 60)} min to full` : ""}`}
          >
            {battery.isCharging && (
              <i className="nf nf-md-power_plug charging-icon" />
            )}
            {getBatteryIcon(battery)}
            {Math.round(battery.chargePercent)}%
          </div>
        )}

        {weather && (
          <div
            className="weather"
            title={`Weather: ${weather.status.replace(/_/g, " ")} | ${Math.round(weather.celsiusTemp)}°C | Wind: ${weather.windSpeed} km/h`}
          >
            {getWeatherIcon(weather)}
            {Math.round(weather.celsiusTemp)}°C
          </div>
        )}
      </div>
    </div>
  );
}
