# weather.py
import os
import sys
import json
import time
import urllib.request
import urllib.parse
from datetime import datetime, timedelta

API_KEY = os.environ.get("OPENWEATHER_API_KEY", "YOUR_API_KEY_HERE")
BASE_URL = "https://api.openweathermap.org/data/2.5"
UNITS = "metric" if os.environ.get("WEATHER_UNIT") != "imperial" else "imperial"
CACHE = {}
CACHE_TTL = 600  # seconds

def get_weather(city):
    cache_key = f"weather_{city}_{UNITS}"
    if cache_key in CACHE:
        data, timestamp = CACHE[cache_key]
        if time.time() - timestamp < CACHE_TTL:
            return data
    url = f"{BASE_URL}/weather?q={urllib.parse.quote(city)}&appid={API_KEY}&units={UNITS}"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            CACHE[cache_key] = (data, time.time())
            return data
    except Exception as e:
        print(f"Error fetching weather: {e}")
        return None

def get_forecast(city):
    cache_key = f"forecast_{city}_{UNITS}"
    if cache_key in CACHE:
        data, timestamp = CACHE[cache_key]
        if time.time() - timestamp < CACHE_TTL:
            return data
    url = f"{BASE_URL}/forecast?q={urllib.parse.quote(city)}&appid={API_KEY}&units={UNITS}"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            CACHE[cache_key] = (data, time.time())
            return data
    except Exception as e:
        print(f"Error fetching forecast: {e}")
        return None

def icon_for_code(code):
    mapping = {
        "01d": "☀️", "01n": "🌙",
        "02d": "⛅", "02n": "☁️",
        "03d": "☁️", "03n": "☁️",
        "04d": "☁️", "04n": "☁️",
        "09d": "🌧️", "09n": "🌧️",
        "10d": "🌦️", "10n": "🌧️",
        "11d": "⛈️", "11n": "⛈️",
        "13d": "❄️", "13n": "❄️",
        "50d": "🌫️", "50n": "🌫️"
    }
    return mapping.get(code, "🌈")

def display_weather(data):
    if not data or data.get("cod") != 200:
        print("Could not retrieve weather.")
        return
    city = data.get("name", "Unknown")
    country = data.get("sys", {}).get("country", "")
    temp = data["main"]["temp"]
    feels_like = data["main"]["feels_like"]
    humidity = data["main"]["humidity"]
    pressure = data["main"]["pressure"]
    wind = data["wind"]["speed"]
    desc = data["weather"][0]["description"].capitalize()
    icon_code = data["weather"][0]["icon"]
    icon = icon_for_code(icon_code)
    dt = datetime.fromtimestamp(data["dt"]).strftime("%Y-%m-%d %H:%M")
    temp_unit = "°C" if UNITS == "metric" else "°F"
    wind_unit = "m/s" if UNITS == "metric" else "mph"

    print(f"\n{icon} Weather in {city}{', ' + country if country else ''} ({dt})")
    print(f"Temperature: {temp:.1f}{temp_unit} (feels like {feels_like:.1f}{temp_unit})")
    print(f"Humidity: {humidity}%   Pressure: {pressure} hPa")
    print(f"Wind: {wind:.1f} {wind_unit}")
    print(f"Description: {desc}")

def display_forecast(data):
    if not data or data.get("cod") != "200":
        return
    print("\n📅 5‑Day Forecast:")
    days = {}
    for entry in data["list"][:40]:  # 5 days * 8 entries = 40
        dt = datetime.fromtimestamp(entry["dt"])
        date_key = dt.strftime("%Y-%m-%d")
        if date_key not in days:
            days[date_key] = {"min": entry["main"]["temp_min"], "max": entry["main"]["temp_max"], "icon": entry["weather"][0]["icon"]}
        else:
            days[date_key]["min"] = min(days[date_key]["min"], entry["main"]["temp_min"])
            days[date_key]["max"] = max(days[date_key]["max"], entry["main"]["temp_max"])
    temp_unit = "°C" if UNITS == "metric" else "°F"
    for date, vals in list(days.items())[:5]:
        icon = icon_for_code(vals["icon"])
        print(f"{date}: {icon} {int(vals['max'])}{temp_unit} / {int(vals['min'])}{temp_unit}")

def main():
    if not API_KEY or API_KEY == "YOUR_API_KEY_HERE":
        print("Please set OPENWEATHER_API_KEY environment variable.")
        sys.exit(1)
    city = sys.argv[1] if len(sys.argv) > 1 else "London"
    weather = get_weather(city)
    if weather:
        display_weather(weather)
        forecast = get_forecast(city)
        if forecast:
            display_forecast(forecast)
    else:
        print("Failed to get weather data.")

if __name__ == "__main__":
    main()
