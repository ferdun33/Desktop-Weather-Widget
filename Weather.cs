// Weather.cs
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using System.Linq;
using System.Runtime.CompilerServices;

class WeatherProgram
{
    private static readonly string apiKey = Environment.GetEnvironmentVariable("OPENWEATHER_API_KEY") ?? "YOUR_API_KEY_HERE";
    private static readonly string units = Environment.GetEnvironmentVariable("WEATHER_UNIT") == "imperial" ? "imperial" : "metric";
    private static readonly Dictionary<string, (object data, DateTime timestamp)> cache = new();
    private static readonly int cacheTTL = 600;
    private static readonly HttpClient client = new HttpClient();

    static async Task<JsonElement?> FetchData(string url)
    {
        try
        {
            var response = await client.GetStringAsync(url);
            using var doc = JsonDocument.Parse(response);
            return doc.RootElement.Clone();
        }
        catch { return null; }
    }

    static async Task<JsonElement?> GetWeather(string city)
    {
        string key = $"weather_{city}_{units}";
        if (cache.TryGetValue(key, out var entry))
        {
            if ((DateTime.Now - entry.timestamp).TotalSeconds < cacheTTL)
                return (JsonElement)entry.data;
        }
        string url = $"https://api.openweathermap.org/data/2.5/weather?q={Uri.EscapeDataString(city)}&appid={apiKey}&units={units}";
        var data = await FetchData(url);
        if (data.HasValue)
            cache[key] = (data.Value, DateTime.Now);
        return data;
    }

    static async Task<JsonElement?> GetForecast(string city)
    {
        string key = $"forecast_{city}_{units}";
        if (cache.TryGetValue(key, out var entry))
        {
            if ((DateTime.Now - entry.timestamp).TotalSeconds < cacheTTL)
                return (JsonElement)entry.data;
        }
        string url = $"https://api.openweathermap.org/data/2.5/forecast?q={Uri.EscapeDataString(city)}&appid={apiKey}&units={units}";
        var data = await FetchData(url);
        if (data.HasValue)
            cache[key] = (data.Value, DateTime.Now);
        return data;
    }

    static string IconForCode(string code)
    {
        var map = new Dictionary<string, string>
        {
            {"01d", "☀️"}, {"01n", "🌙"},
            {"02d", "⛅"}, {"02n", "☁️"},
            {"03d", "☁️"}, {"03n", "☁️"},
            {"04d", "☁️"}, {"04n", "☁️"},
            {"09d", "🌧️"}, {"09n", "🌧️"},
            {"10d", "🌦️"}, {"10n", "🌧️"},
            {"11d", "⛈️"}, {"11n", "⛈️"},
            {"13d", "❄️"}, {"13n", "❄️"},
            {"50d", "🌫️"}, {"50n", "🌫️"}
        };
        return map.GetValueOrDefault(code, "🌈");
    }

    static void DisplayWeather(JsonElement data)
    {
        if (data.ValueKind == JsonValueKind.Undefined || data.GetProperty("cod").GetInt32() != 200)
        {
            Console.WriteLine("Could not retrieve weather.");
            return;
        }
        var city = data.GetProperty("name").GetString();
        var country = data.TryGetProperty("sys", out var sys) ? sys.GetProperty("country").GetString() : "";
        var dt = DateTimeOffset.FromUnixTimeSeconds(data.GetProperty("dt").GetInt64()).LocalDateTime;
        var icon = IconForCode(data.GetProperty("weather")[0].GetProperty("icon").GetString());
        var main = data.GetProperty("main");
        var temp = main.GetProperty("temp").GetDouble();
        var feels = main.GetProperty("feels_like").GetDouble();
        var humidity = main.GetProperty("humidity").GetInt32();
        var pressure = main.GetProperty("pressure").GetInt32();
        var wind = data.GetProperty("wind").GetProperty("speed").GetDouble();
        var desc = data.GetProperty("weather")[0].GetProperty("description").GetString();
        desc = char.ToUpper(desc[0]) + desc.Substring(1);
        var tempUnit = units == "metric" ? "°C" : "°F";
        var windUnit = units == "metric" ? "m/s" : "mph";
        Console.WriteLine($"\n{icon} Weather in {city}{(string.IsNullOrEmpty(country) ? "" : ", " + country)} ({dt:yyyy-MM-dd HH:mm})");
        Console.WriteLine($"Temperature: {temp:F1}{tempUnit} (feels like {feels:F1}{tempUnit})");
        Console.WriteLine($"Humidity: {humidity}%   Pressure: {pressure} hPa");
        Console.WriteLine($"Wind: {wind:F1} {windUnit}");
        Console.WriteLine($"Description: {desc}");
    }

    static void DisplayForecast(JsonElement data)
    {
        if (data.ValueKind == JsonValueKind.Undefined || data.GetProperty("cod").GetString() != "200") return;
        Console.WriteLine("\n📅 5‑Day Forecast:");
        var days = new Dictionary<string, (double min, double max, string icon)>();
        var list = data.GetProperty("list");
        foreach (var entry in list.EnumerateArray().Take(40))
        {
            var dt = DateTimeOffset.FromUnixTimeSeconds(entry.GetProperty("dt").GetInt64());
            var dateKey = dt.ToString("yyyy-MM-dd");
            var min = entry.GetProperty("main").GetProperty("temp_min").GetDouble();
            var max = entry.GetProperty("main").GetProperty("temp_max").GetDouble();
            var icon = entry.GetProperty("weather")[0].GetProperty("icon").GetString();
            if (!days.ContainsKey(dateKey))
                days[dateKey] = (min, max, icon);
            else
            {
                var cur = days[dateKey];
                days[dateKey] = (Math.Min(cur.min, min), Math.Max(cur.max, max), cur.icon);
            }
        }
        var tempUnit = units == "metric" ? "°C" : "°F";
        int count = 0;
        foreach (var kv in days)
        {
            if (count++ >= 5) break;
            var icon = IconForCode(kv.Value.icon);
            Console.WriteLine($"{kv.Key}: {icon} {Math.Round(kv.Value.max)}° / {Math.Round(kv.Value.min)}°");
        }
    }

    static async Task Main(string[] args)
    {
        if (apiKey == "YOUR_API_KEY_HERE")
        {
            Console.Error.WriteLine("Please set OPENWEATHER_API_KEY environment variable.");
            Environment.Exit(1);
        }
        string city = args.Length > 0 ? args[0] : "London";
        var weather = await GetWeather(city);
        if (weather.HasValue)
        {
            DisplayWeather(weather.Value);
            var forecast = await GetForecast(city);
            if (forecast.HasValue)
                DisplayForecast(forecast.Value);
        }
        else
            Console.WriteLine("Failed to get weather data.");
    }
}
