export function getNetworkIcon(networkOutput: any) {
  switch (networkOutput.defaultInterface?.type) {
    case "ethernet":
      return <i className="nf nf-md-ethernet_cable" />;
    case "wifi":
      if (networkOutput.defaultGateway?.signalStrength >= 80)
        return <i className="nf nf-md-wifi_strength_4" />;
      if (networkOutput.defaultGateway?.signalStrength >= 65)
        return <i className="nf nf-md-wifi_strength_3" />;
      if (networkOutput.defaultGateway?.signalStrength >= 40)
        return <i className="nf nf-md-wifi_strength_2" />;
      if (networkOutput.defaultGateway?.signalStrength >= 25)
        return <i className="nf nf-md-wifi_strength_1" />;
      return <i className="nf nf-md-wifi_strength_outline" />;
    default:
      return <i className="nf nf-md-wifi_strength_off_outline" />;
  }
}

export function getBatteryIcon(batteryOutput: any) {
  if (batteryOutput.chargePercent > 90)
    return <i className="nf nf-fa-battery_4" />;
  if (batteryOutput.chargePercent > 70)
    return <i className="nf nf-fa-battery_3" />;
  if (batteryOutput.chargePercent > 40)
    return <i className="nf nf-fa-battery_2" />;
  if (batteryOutput.chargePercent > 20)
    return <i className="nf nf-fa-battery_1" />;
  return <i className="nf nf-fa-battery_0" />;
}

export function getWeatherIcon(weatherOutput: any) {
  switch (weatherOutput.status) {
    case "clear_day":
      return <i className="nf nf-weather-day_sunny" />;
    case "clear_night":
      return <i className="nf nf-weather-night_clear" />;
    case "cloudy_day":
      return <i className="nf nf-weather-day_cloudy" />;
    case "cloudy_night":
      return <i className="nf nf-weather-night_alt_cloudy" />;
    case "light_rain_day":
      return <i className="nf nf-weather-day_sprinkle" />;
    case "light_rain_night":
      return <i className="nf nf-weather-night_alt_sprinkle" />;
    case "heavy_rain_day":
      return <i className="nf nf-weather-day_rain" />;
    case "heavy_rain_night":
      return <i className="nf nf-weather-night_alt_rain" />;
    case "snow_day":
      return <i className="nf nf-weather-day_snow" />;
    case "snow_night":
      return <i className="nf nf-weather-night_alt_snow" />;
    case "thunder_day":
      return <i className="nf nf-weather-day_lightning" />;
    case "thunder_night":
      return <i className="nf nf-weather-night_alt_lightning" />;
  }
}
