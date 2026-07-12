# weather.rb
require 'net/http'
require 'json'
require 'time'

API_KEY = ENV['OPENWEATHER_API_KEY'] || 'YOUR_API_KEY_HERE'
UNITS = ENV['WEATHER_UNIT'] == 'imperial' ? 'imperial' : 'metric'
CACHE = {}
CACHE_TTL = 600

def fetch_data(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  if response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  else
    nil
  end
end

def get_weather(city)
  key = "weather_#{city}_#{UNITS}"
  if CACHE.key?(key) && (Time.now - CACHE[key][:timestamp]) < CACHE_TTL
    return CACHE[key][:data]
  end
  url = "https://api.openweathermap.org/data/2.5/weather?q=#{URI.encode_www_form_component(city)}&appid=#{API_KEY}&units=#{UNITS}"
  data = fetch_data(url)
  CACHE[key] = { data: data, timestamp: Time.now } if data
  data
end

def get_forecast(city)
  key = "forecast_#{city}_#{UNITS}"
  if CACHE.key?(key) && (Time.now - CACHE[key][:timestamp]) < CACHE_TTL
    return CACHE[key][:data]
  end
  url = "https://api.openweathermap.org/data/2.5/forecast?q=#{URI.encode_www_form_component(city)}&appid=#{API_KEY}&units=#{UNITS}"
  data = fetch_data(url)
  CACHE[key] = { data: data, timestamp: Time.now } if data
  data
end

def icon_for_code(code)
  map = {
    '01d' => '☀️', '01n' => '🌙',
    '02d' => '⛅', '02n' => '☁️',
    '03d' => '☁️', '03n' => '☁️',
    '04d' => '☁️', '04n' => '☁️',
    '09d' => '🌧️', '09n' => '🌧️',
    '10d' => '🌦️', '10n' => '🌧️',
    '11d' => '⛈️', '11n' => '⛈️',
    '13d' => '❄️', '13n' => '❄️',
    '50d' => '🌫️', '50n' => '🌫️'
  }
  map[code] || '🌈'
end

def display_weather(data)
  if data.nil? || data['cod'] != 200
    puts 'Could not retrieve weather.'
    return
  end
  city = data['name']
  country = data['sys']['country'] || ''
  dt = Time.at(data['dt']).strftime('%Y-%m-%d %H:%M')
  icon = icon_for_code(data['weather'][0]['icon'])
  temp_unit = UNITS == 'metric' ? '°C' : '°F'
  wind_unit = UNITS == 'metric' ? 'm/s' : 'mph'
  desc = data['weather'][0]['description'].capitalize
  puts "\n#{icon} Weather in #{city}#{country.empty? ? '' : ', ' + country} (#{dt})"
  puts "Temperature: #{data['main']['temp'].round(1)}#{temp_unit} (feels like #{data['main']['feels_like'].round(1)}#{temp_unit})"
  puts "Humidity: #{data['main']['humidity']}%   Pressure: #{data['main']['pressure']} hPa"
  puts "Wind: #{data['wind']['speed'].round(1)} #{wind_unit}"
  puts "Description: #{desc}"
end

def display_forecast(data)
  if data.nil? || data['cod'] != '200'
    return
  end
  puts "\n📅 5‑Day Forecast:"
  days = {}
  data['list'].first(40).each do |entry|
    dt = Time.at(entry['dt'])
    date_key = dt.strftime('%Y-%m-%d')
    unless days[date_key]
      days[date_key] = { min: entry['main']['temp_min'], max: entry['main']['temp_max'], icon: entry['weather'][0]['icon'] }
    else
      days[date_key][:min] = [days[date_key][:min], entry['main']['temp_min']].min
      days[date_key][:max] = [days[date_key][:max], entry['main']['temp_max']].max
    end
  end
  temp_unit = UNITS == 'metric' ? '°C' : '°F'
  count = 0
  days.each do |date, vals|
    break if count >= 5
    icon = icon_for_code(vals[:icon])
    puts "#{date}: #{icon} #{vals[:max].round}° / #{vals[:min].round}°"
    count += 1
  end
end

def main
  if API_KEY == 'YOUR_API_KEY_HERE'
    $stderr.puts 'Please set OPENWEATHER_API_KEY environment variable.'
    exit 1
  end
  city = ARGV[0] || 'London'
  weather = get_weather(city)
  if weather
    display_weather(weather)
    forecast = get_forecast(city)
    display_forecast(forecast) if forecast
  else
    puts 'Failed to get weather data.'
  end
end

main if __FILE__ == $0
