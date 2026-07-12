// weather.go
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"time"
)

var apiKey = os.Getenv("OPENWEATHER_API_KEY")
var units = "metric"
var cache = make(map[string]cacheEntry)
const cacheTTL = 600

type cacheEntry struct {
	data      interface{}
	timestamp time.Time
}

type weatherData struct {
	Weather []struct {
		Main        string `json:"main"`
		Description string `json:"description"`
		Icon        string `json:"icon"`
	} `json:"weather"`
	Main struct {
		Temp      float64 `json:"temp"`
		FeelsLike float64 `json:"feels_like"`
		Humidity  int     `json:"humidity"`
		Pressure  int     `json:"pressure"`
	} `json:"main"`
	Wind struct {
		Speed float64 `json:"speed"`
	} `json:"wind"`
	Name string `json:"name"`
	Sys  struct {
		Country string `json:"country"`
	} `json:"sys"`
	Dt int64 `json:"dt"`
	Cod int   `json:"cod"`
}

type forecastData struct {
	Cod string `json:"cod"`
	List []struct {
		Dt   int64 `json:"dt"`
		Main struct {
			TempMin float64 `json:"temp_min"`
			TempMax float64 `json:"temp_max"`
		} `json:"main"`
		Weather []struct {
			Icon string `json:"icon"`
		} `json:"weather"`
	} `json:"list"`
}

func getWeather(city string) (*weatherData, error) {
	cacheKey := "weather_" + city + "_" + units
	if entry, ok := cache[cacheKey]; ok {
		if time.Since(entry.timestamp).Seconds() < cacheTTL {
			return entry.data.(*weatherData), nil
		}
	}
	base := "https://api.openweathermap.org/data/2.5/weather"
	params := url.Values{}
	params.Set("q", city)
	params.Set("appid", apiKey)
	params.Set("units", units)
	fullURL := base + "?" + params.Encode()
	resp, err := http.Get(fullURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	var w weatherData
	if err := json.Unmarshal(body, &w); err != nil {
		return nil, err
	}
	cache[cacheKey] = cacheEntry{data: &w, timestamp: time.Now()}
	return &w, nil
}

func getForecast(city string) (*forecastData, error) {
	cacheKey := "forecast_" + city + "_" + units
	if entry, ok := cache[cacheKey]; ok {
		if time.Since(entry.timestamp).Seconds() < cacheTTL {
			return entry.data.(*forecastData), nil
		}
	}
	base := "https://api.openweathermap.org/data/2.5/forecast"
	params := url.Values{}
	params.Set("q", city)
	params.Set("appid", apiKey)
	params.Set("units", units)
	fullURL := base + "?" + params.Encode()
	resp, err := http.Get(fullURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	var f forecastData
	if err := json.Unmarshal(body, &f); err != nil {
		return nil, err
	}
	cache[cacheKey] = cacheEntry{data: &f, timestamp: time.Now()}
	return &f, nil
}

func iconForCode(code string) string {
	m := map[string]string{
		"01d": "☀️", "01n": "🌙",
		"02d": "⛅", "02n": "☁️",
		"03d": "☁️", "03n": "☁️",
		"04d": "☁️", "04n": "☁️",
		"09d": "🌧️", "09n": "🌧️",
		"10d": "🌦️", "10n": "🌧️",
		"11d": "⛈️", "11n": "⛈️",
		"13d": "❄️", "13n": "❄️",
		"50d": "🌫️", "50n": "🌫️",
	}
	if val, ok := m[code]; ok {
		return val
	}
	return "🌈"
}

func displayWeather(w *weatherData) {
	if w == nil || w.Cod != 200 {
		fmt.Println("Could not retrieve weather.")
		return
	}
	icon := iconForCode(w.Weather[0].Icon)
	dt := time.Unix(w.Dt, 0).Format("2006-01-02 15:04")
	tempUnit := "°C"
	windUnit := "m/s"
	if units == "imperial" {
		tempUnit = "°F"
		windUnit = "mph"
	}
	fmt.Printf("\n%s Weather in %s%s (%s)\n", icon, w.Name, func() string {
		if w.Sys.Country != "" {
			return ", " + w.Sys.Country
		}
		return ""
	}(), dt)
	fmt.Printf("Temperature: %.1f%s (feels like %.1f%s)\n", w.Main.Temp, tempUnit, w.Main.FeelsLike, tempUnit)
	fmt.Printf("Humidity: %d%%   Pressure: %d hPa\n", w.Main.Humidity, w.Main.Pressure)
	fmt.Printf("Wind: %.1f %s\n", w.Wind.Speed, windUnit)
	fmt.Printf("Description: %s\n", w.Weather[0].Description)
}

func displayForecast(f *forecastData) {
	if f == nil || f.Cod != "200" {
		return
	}
	fmt.Println("\n📅 5‑Day Forecast:")
	days := make(map[string]struct{ Min, Max float64; Icon string })
	for _, entry := range f.List[:40] {
		dt := time.Unix(entry.Dt, 0)
		dateKey := dt.Format("2006-01-02")
		if _, ok := days[dateKey]; !ok {
			days[dateKey] = struct{ Min, Max float64; Icon string }{
				Min:  entry.Main.TempMin,
				Max:  entry.Main.TempMax,
				Icon: entry.Weather[0].Icon,
			}
		} else {
			d := days[dateKey]
			if entry.Main.TempMin < d.Min {
				d.Min = entry.Main.TempMin
			}
			if entry.Main.TempMax > d.Max {
				d.Max = entry.Main.TempMax
			}
			days[dateKey] = d
		}
	}
	tempUnit := "°C"
	if units == "imperial" {
		tempUnit = "°F"
	}
	count := 0
	for date, vals := range days {
		if count >= 5 {
			break
		}
		icon := iconForCode(vals.Icon)
		fmt.Printf("%s: %s %.0f%s / %.0f%s\n", date, icon, vals.Max, tempUnit, vals.Min, tempUnit)
		count++
	}
}

func main() {
	if apiKey == "" {
		fmt.Println("Please set OPENWEATHER_API_KEY environment variable.")
		os.Exit(1)
	}
	if os.Getenv("WEATHER_UNIT") == "imperial" {
		units = "imperial"
	}
	city := "London"
	if len(os.Args) > 1 {
		city = os.Args[1]
	}
	weather, err := getWeather(city)
	if err != nil {
		fmt.Println("Error getting weather:", err)
		return
	}
	displayWeather(weather)
	forecast, err := getForecast(city)
	if err == nil {
		displayForecast(forecast)
	}
}
