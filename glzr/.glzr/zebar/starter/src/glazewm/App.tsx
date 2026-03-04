import { useState, useEffect } from "react";
import * as zebar from "zebar";
import { getBatteryIcon, getWeatherIcon } from "./icons";
import "./styles.css";

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

  useEffect(() => {
    providers.onOutput(() => setOutput(providers.outputMap));
  }, []);

  const glazewm = output.glazewm;
  const cpu = output.cpu;
  const battery = output.battery;
  const memory = output.memory;
  const weather = output.weather;


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
