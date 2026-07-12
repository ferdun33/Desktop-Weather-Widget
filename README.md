🌦️ Desktop Weather Widget

A sleek, cross‑platform **weather widget** for your terminal.  
Displays current weather conditions, temperature, humidity, wind speed, and a 5‑day forecast with emoji icons and ANSI colors.  
Built in **7 programming languages** – just run and enjoy the weather!

## ✨ Features
- **Current weather** – temperature, feels‑like, humidity, pressure, wind, and description.
- **5‑day forecast** – shows min/max temperature and weather icon for each day.
- **Colorful output** – uses ANSI colors for better readability.
- **Emoji icons** – ☀️, 🌧️, ☁️, ❄️, etc., based on weather conditions.
- **City selection** – enter any city name (default: London).
- **API caching** – caches results for 10 minutes to reduce API calls.
- **Unit toggle** – °C or °F (configurable).
- **No external GUI** – runs in any terminal, perfect for servers or minimal setups.

## 🗂 Languages & Files
| Language          | File                |
|-------------------|---------------------|
| Python            | `weather.py`        |
| Go                | `weather.go`        |
| JavaScript (Node) | `weather.js`        |
| C#                | `Weather.cs`        |
| Java              | `Weather.java`      |
| Ruby              | `weather.rb`        |
| Swift             | `weather.swift`     |

## 🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.  
You'll need a **free API key** from [OpenWeatherMap](https://openweathermap.org/api).

1. Sign up and get your API key.
2. Set it as an environment variable `OPENWEATHER_API_KEY` or replace it in the code.
3. Run the script.

| Language | Command |
|----------|---------|
| Python   | `python weather.py [city]` |
| Go       | `go run weather.go [city]` |
| JavaScript | `node weather.js [city]` |
| C#       | `dotnet run [city]` (or `csc Weather.cs && Weather.exe [city]`) |
| Java     | `javac Weather.java && java Weather [city]` |
| Ruby     | `ruby weather.rb [city]` |
| Swift    | `swift weather.swift [city]` |

If no city is given, defaults to `London`.

## 📊 Example Output
🌤️ Weather in London (2026-07-12 14:30)
Temperature: 18°C (feels like 16°C)
Humidity: 72% Pressure: 1012 hPa
Wind: 5.2 m/s
Description: partly cloudy

📅 5‑Day Forecast:
Mon 12 Jul: ☀️ 22°C / 14°C
Tue 13 Jul: 🌧️ 19°C / 12°C
Wed 14 Jul: ☁️ 20°C / 13°C
Thu 15 Jul: 🌤️ 24°C / 15°C
Fri 16 Jul: ☀️ 26°C / 17°C

text

## 🔧 Environment Variables
- `OPENWEATHER_API_KEY` – your OpenWeatherMap API key (required).
- `WEATHER_UNIT` – set to `imperial` for Fahrenheit, otherwise Celsius.

## 🤝 Contributing
Add more features (hourly forecast, location auto‑detect) – PRs welcome!

## 📜 License
MIT – use freely.
