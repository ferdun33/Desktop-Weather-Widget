// weather.swift
import Foundation

let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_API_KEY_HERE"
let units = ProcessInfo.processInfo.environment["WEATHER_UNIT"] == "imperial" ? "imperial" : "metric"
var cache: [String: (data: Any, timestamp: TimeInterval)] = [:]
let cacheTTL: TimeInterval = 600

func fetchData(urlString: String) -> Any? {
    guard let url = URL(string: urlString) else { return nil }
    let semaphore = DispatchSemaphore(value: 0)
    var result: Any? = nil
    let task = URLSession.shared.dataTask(with: url) { data, _, error in
        defer { semaphore.signal() }
        guard let data = data, error == nil else { return }
        do {
            result = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            print("JSON error: \(error)")
        }
    }
    task.resume()
    semaphore.wait()
    return result
}

func getWeather(city: String) -> Any? {
    let key = "weather_\(city)_\(units)"
    if let entry = cache[key] {
        if Date().timeIntervalSince1970 - entry.timestamp < cacheTTL {
            return entry.data
        }
    }
    let url = "https://api.openweathermap.org/data/2.5/weather?q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)&appid=\(apiKey)&units=\(units)"
    let data = fetchData(urlString: url)
    if let data = data {
        cache[key] = (data: data, timestamp: Date().timeIntervalSince1970)
    }
    return data
}

func getForecast(city: String) -> Any? {
    let key = "forecast_\(city)_\(units)"
    if let entry = cache[key] {
        if Date().timeIntervalSince1970 - entry.timestamp < cacheTTL {
            return entry.data
        }
    }
    let url = "https://api.openweathermap.org/data/2.5/forecast?q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)&appid=\(apiKey)&units=\(units)"
    let data = fetchData(urlString: url)
    if let data = data {
        cache[key] = (data: data, timestamp: Date().timeIntervalSince1970)
    }
    return data
}

func iconForCode(_ code: String) -> String {
    let map: [String: String] = [
        "01d": "☀️", "01n": "🌙",
        "02d": "⛅", "02n": "☁️",
        "03d": "☁️", "03n": "☁️",
        "04d": "☁️", "04n": "☁️",
        "09d": "🌧️", "09n": "🌧️",
        "10d": "🌦️", "10n": "🌧️",
        "11d": "⛈️", "11n": "⛈️",
        "13d": "❄️", "13n": "❄️",
        "50d": "🌫️", "50n": "🌫️"
    ]
    return map[code] ?? "🌈"
}

func displayWeather(_ data: Any?) {
    guard let json = data as? [String: Any],
          let cod = json["cod"] as? Int, cod == 200 else {
        print("Could not retrieve weather.")
        return
    }
    let city = json["name"] as? String ?? "Unknown"
    let country = (json["sys"] as? [String: Any])?["country"] as? String ?? ""
    let dt = Date(timeIntervalSince1970: json["dt"] as? TimeInterval ?? 0)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    let dtStr = dateFormatter.string(from: dt)
    let weatherArr = json["weather"] as? [[String: Any]] ?? []
    let weather = weatherArr.first ?? [:]
    let icon = iconForCode(weather["icon"] as? String ?? "")
    let main = json["main"] as? [String: Any] ?? [:]
    let temp = main["temp"] as? Double ?? 0
    let feels = main["feels_like"] as? Double ?? 0
    let humidity = main["humidity"] as? Int ?? 0
    let pressure = main["pressure"] as? Int ?? 0
    let wind = (json["wind"] as? [String: Any])?["speed"] as? Double ?? 0
    let desc = weather["description"] as? String ?? ""
    let tempUnit = units == "metric" ? "°C" : "°F"
    let windUnit = units == "metric" ? "m/s" : "mph"
    print("\n\(icon) Weather in \(city)\(country.isEmpty ? "" : ", " + country) (\(dtStr))")
    print("Temperature: \(String(format: "%.1f", temp))\(tempUnit) (feels like \(String(format: "%.1f", feels))\(tempUnit))")
    print("Humidity: \(humidity)%   Pressure: \(pressure) hPa")
    print("Wind: \(String(format: "%.1f", wind)) \(windUnit)")
    print("Description: \(desc.capitalized)")
}

func displayForecast(_ data: Any?) {
    guard let json = data as? [String: Any],
          let cod = json["cod"] as? String, cod == "200" else { return }
    let list = json["list"] as? [[String: Any]] ?? []
    var days: [String: (min: Double, max: Double, icon: String)] = [:]
    for entry in list.prefix(40) {
        let dt = Date(timeIntervalSince1970: entry["dt"] as? TimeInterval ?? 0)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: dt)
        let main = entry["main"] as? [String: Any] ?? [:]
        let min = main["temp_min"] as? Double ?? 0
        let max = main["temp_max"] as? Double ?? 0
        let weatherArr = entry["weather"] as? [[String: Any]] ?? []
        let icon = weatherArr.first?["icon"] as? String ?? ""
        if let existing = days[dateKey] {
            days[dateKey] = (min: min(existing.min, min), max: max(existing.max, max), icon: existing.icon)
        } else {
            days[dateKey] = (min: min, max: max, icon: icon)
        }
    }
    let tempUnit = units == "metric" ? "°C" : "°F"
    var count = 0
    for (date, vals) in days.sorted(by: { $0.key < $1.key }) {
        if count >= 5 { break }
        let icon = iconForCode(vals.icon)
        print("\(date): \(icon) \(Int(vals.max))° / \(Int(vals.min))°")
        count += 1
    }
}

func main() {
    if apiKey == "YOUR_API_KEY_HERE" {
        fputs("Please set OPENWEATHER_API_KEY environment variable.\n", stderr)
        exit(1)
    }
    let city = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "London"
    if let weather = getWeather(city: city) {
        displayWeather(weather)
        if let forecast = getForecast(city: city) {
            displayForecast(forecast)
        }
    } else {
        print("Failed to get weather data.")
    }
}

main()
