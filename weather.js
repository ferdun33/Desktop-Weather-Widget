// weather.js
const https = require('https');
const querystring = require('querystring');

const apiKey = process.env.OPENWEATHER_API_KEY || 'YOUR_API_KEY_HERE';
const units = process.env.WEATHER_UNIT === 'imperial' ? 'imperial' : 'metric';
const cache = {};
const CACHE_TTL = 600;

function fetchData(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(e);
                }
            });
        }).on('error', reject);
    });
}

function getWeather(city) {
    const cacheKey = `weather_${city}_${units}`;
    if (cache[cacheKey] && (Date.now() - cache[cacheKey].timestamp) / 1000 < CACHE_TTL) {
        return Promise.resolve(cache[cacheKey].data);
    }
    const params = querystring.stringify({ q: city, appid: apiKey, units });
    const url = `https://api.openweathermap.org/data/2.5/weather?${params}`;
    return fetchData(url).then(data => {
        cache[cacheKey] = { data, timestamp: Date.now() };
        return data;
    });
}

function getForecast(city) {
    const cacheKey = `forecast_${city}_${units}`;
    if (cache[cacheKey] && (Date.now() - cache[cacheKey].timestamp) / 1000 < CACHE_TTL) {
        return Promise.resolve(cache[cacheKey].data);
    }
    const params = querystring.stringify({ q: city, appid: apiKey, units });
    const url = `https://api.openweathermap.org/data/2.5/forecast?${params}`;
    return fetchData(url).then(data => {
        cache[cacheKey] = { data, timestamp: Date.now() };
        return data;
    });
}

function iconForCode(code) {
    const map = {
        '01d': '☀️', '01n': '🌙',
        '02d': '⛅', '02n': '☁️',
        '03d': '☁️', '03n': '☁️',
        '04d': '☁️', '04n': '☁️',
        '09d': '🌧️', '09n': '🌧️',
        '10d': '🌦️', '10n': '🌧️',
        '11d': '⛈️', '11n': '⛈️',
        '13d': '❄️', '13n': '❄️',
        '50d': '🌫️', '50n': '🌫️'
    };
    return map[code] || '🌈';
}

function displayWeather(data) {
    if (!data || data.cod !== 200) {
        console.log('Could not retrieve weather.');
        return;
    }
    const city = data.name;
    const country = data.sys.country || '';
    const dt = new Date(data.dt * 1000).toLocaleString();
    const icon = iconForCode(data.weather[0].icon);
    const tempUnit = units === 'metric' ? '°C' : '°F';
    const windUnit = units === 'metric' ? 'm/s' : 'mph';
    const desc = data.weather[0].description.charAt(0).toUpperCase() + data.weather[0].description.slice(1);
    console.log(`\n${icon} Weather in ${city}${country ? ', ' + country : ''} (${dt})`);
    console.log(`Temperature: ${data.main.temp.toFixed(1)}${tempUnit} (feels like ${data.main.feels_like.toFixed(1)}${tempUnit})`);
    console.log(`Humidity: ${data.main.humidity}%   Pressure: ${data.main.pressure} hPa`);
    console.log(`Wind: ${data.wind.speed.toFixed(1)} ${windUnit}`);
    console.log(`Description: ${desc}`);
}

function displayForecast(data) {
    if (!data || data.cod !== "200") return;
    console.log('\n📅 5‑Day Forecast:');
    const days = {};
    for (const entry of data.list.slice(0, 40)) {
        const dt = new Date(entry.dt * 1000);
        const dateKey = dt.toISOString().slice(0,10);
        if (!days[dateKey]) {
            days[dateKey] = { min: entry.main.temp_min, max: entry.main.temp_max, icon: entry.weather[0].icon };
        } else {
            days[dateKey].min = Math.min(days[dateKey].min, entry.main.temp_min);
            days[dateKey].max = Math.max(days[dateKey].max, entry.main.temp_max);
        }
    }
    const tempUnit = units === 'metric' ? '°C' : '°F';
    let count = 0;
    for (const [date, vals] of Object.entries(days)) {
        if (count++ >= 5) break;
        const icon = iconForCode(vals.icon);
        console.log(`${date}: ${icon} ${Math.round(vals.max)}${tempUnit} / ${Math.round(vals.min)}${tempUnit}`);
    }
}

async function main() {
    if (apiKey === 'YOUR_API_KEY_HERE') {
        console.error('Please set OPENWEATHER_API_KEY environment variable.');
        process.exit(1);
    }
    const city = process.argv[2] || 'London';
    try {
        const weather = await getWeather(city);
        displayWeather(weather);
        const forecast = await getForecast(city);
        displayForecast(forecast);
    } catch (err) {
        console.error('Error:', err.message);
    }
}

if (require.main === module) main();
