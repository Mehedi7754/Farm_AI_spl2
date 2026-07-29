import { Injectable, Logger } from '@nestjs/common';
import { GetWeatherDto } from './dto/get-weather.dto';

@Injectable()
export class WeatherService {
  private readonly logger = new Logger(WeatherService.name);

  async getWeatherForecast(dto: GetWeatherDto) {
    const lat = dto.lat || 23.8103;
    const lng = dto.lng || 90.4125;

    const apiKey = process.env.OPENWEATHER_API_KEY;

    if (!apiKey) {
      this.logger.warn('OPENWEATHER_API_KEY is not set. Returning mock Agro data.');
      return this.getMockAgroWeather(lat, lng);
    }

    try {
      // 1. Fetch Current Weather & Forecast from OpenWeatherMap (OneCall or standard API)
      const weatherUrl = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${apiKey}&units=metric`;
      const forecastUrl = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lng}&appid=${apiKey}&units=metric`;
      
      const [weatherRes, forecastRes] = await Promise.all([
        fetch(weatherUrl),
        fetch(forecastUrl)
      ]);

      if (weatherRes.ok && forecastRes.ok) {
        const weatherData: any = await weatherRes.json();
        const forecastData: any = await forecastRes.json();

        const temp = weatherData.main.temp;
        const wind = weatherData.wind.speed * 3.6; // convert m/s to km/h
        const humidity = weatherData.main.humidity;
        const weatherCode = this.mapOwmToWeatherCode(weatherData.weather[0].id);

        const isHeatStress = temp > 33;
        const isStormWarning = wind > 35;

        const advice = isHeatStress
          ? 'উচ্চ তাপমাত্রা! গবাদি পশুকে পর্যাপ্ত ঠান্ডা পানি দিন ও ছায়াযুক্ত স্থানে রাখুন।'
          : isStormWarning
          ? 'ঝড়ের পূর্বাভাস! পশুকে নিরাপদ পাকা আশ্রয়স্থলে স্থানান্তর করুন।'
          : 'আবহাওয়া স্বাভাবিক। গবাদি পশুর নিয়মিত যত্ন নিন।';

        // Parse Forecast Data (OpenWeatherMap returns 3-hour intervals for 5 days)
        const forecastList: any[] = [];
        const dailyMap = new Map();
        
        for (const item of forecastData.list) {
          const date = item.dt_txt.split(' ')[0];
          if (!dailyMap.has(date)) {
            dailyMap.set(date, {
              date: date,
              weatherCode: this.mapOwmToWeatherCode(item.weather[0].id),
              tempMax: item.main.temp_max,
              tempMin: item.main.temp_min,
              precipitation: item.rain ? item.rain['3h'] || 0 : 0
            });
          } else {
            const existing = dailyMap.get(date);
            existing.tempMax = Math.max(existing.tempMax, item.main.temp_max);
            existing.tempMin = Math.min(existing.tempMin, item.main.temp_min);
            existing.precipitation += (item.rain ? item.rain['3h'] || 0 : 0);
          }
        }

        dailyMap.forEach((val) => forecastList.push(val));

        // 2. Fetch Agro API (Soil Moisture & Temperature)
        // Note: Real implementation requires registering a Polygon first.
        // For demonstration, we simulate fetching soil data if polygon is not set up.
        const soilMoisture = 0.28; // 28% volumetric water content
        const soilTemperature = temp - 2.5; // Soil is usually cooler

        return {
          location: { lat, lng },
          currentTemperature: temp,
          windSpeed: wind,
          humidity: humidity,
          weatherCode,
          isHeatStress,
          isStormWarning,
          agriculturalAdvice: advice,
          source: 'openweathermap',
          forecast: forecastList.slice(0, 7),
          agroData: {
            soilMoisture: soilMoisture,
            soilTemperature: soilTemperature,
            soilStatus: soilMoisture < 0.2 ? 'শুষ্ক (Dry)' : 'স্বাভাবিক (Normal)'
          }
        };
      }
    } catch (err) {
      this.logger.error(`OpenWeatherMap API error: ${err.message}`);
    }

    return this.getMockAgroWeather(lat, lng);
  }

  // Maps OpenWeatherMap codes to our standard codes used by the frontend
  private mapOwmToWeatherCode(owmCode: number): number {
    if (owmCode >= 200 && owmCode < 300) return 95; // Thunderstorm
    if (owmCode >= 300 && owmCode < 600) return 61; // Rain/Drizzle
    if (owmCode >= 600 && owmCode < 700) return 71; // Snow
    if (owmCode >= 700 && owmCode < 800) return 45; // Fog/Mist
    if (owmCode === 800) return 0; // Clear
    if (owmCode > 800) return 1; // Clouds
    return 0;
  }

  private getMockAgroWeather(lat: number, lng: number) {
    const today = new Date();
    const forecastList: any[] = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(today);
      d.setDate(today.getDate() + i);
      forecastList.push({
        date: d.toISOString().split('T')[0],
        weatherCode: i % 3 === 0 ? 0 : 1, // alternate clear and cloudy
        tempMax: 32 - i * 0.5,
        tempMin: 25 - i * 0.3,
        precipitation: i === 2 ? 15.0 : 0
      });
    }

    return {
      location: { lat, lng },
      currentTemperature: 31.0,
      windSpeed: 10.0,
      weatherCode: 1,
      humidity: 70,
      isHeatStress: false,
      isStormWarning: false,
      agriculturalAdvice: 'ওপেন-ওয়েদারম্যাপ এপিআই কি (API Key) সেট করা নেই। মক ডেটা দেখাচ্ছে।',
      source: 'mock-agro',
      forecast: forecastList,
      agroData: {
        soilMoisture: 0.22,
        soilTemperature: 28.5,
        soilStatus: 'স্বাভাবিক (Normal)'
      }
    };
  }

  async getWeatherMapTile(layer: string, z: string, x: string, y: string, res: any) {
    const apiKey = process.env.OPENWEATHER_API_KEY;
    if (!apiKey) {
      return res.status(404).send('API Key missing');
    }
    
    // OWM Weather Maps 1.0
    const url = `https://tile.openweathermap.org/map/${layer}/${z}/${x}/${y}.png?appid=${apiKey}`;
    try {
      const response = await fetch(url);
      if (!response.ok) {
        return res.status(response.status).send('Tile fetch failed');
      }
      const buffer = await response.arrayBuffer();
      res.setHeader('Content-Type', 'image/png');
      // Buffer from is standard in Node environment for converting ArrayBuffer to Buffer
      res.send(Buffer.from(buffer));
    } catch (e) {
      this.logger.error(`Failed to proxy OWM tile: ${e.message}`);
      res.status(500).send('Proxy Error');
    }
  }
}

