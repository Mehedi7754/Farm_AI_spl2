import { Test, TestingModule } from '@nestjs/testing';
import { WeatherService } from './weather.service';

describe('WeatherService', () => {
  let service: WeatherService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [WeatherService],
    }).compile();

    service = module.get<WeatherService>(WeatherService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should return weather forecast and agricultural advice', async () => {
    const res = await service.getWeatherForecast({ lat: 23.8103, lng: 90.4125 });
    expect(res).toBeDefined();
    expect(res.currentTemperature).toBeDefined();
    expect(res.agriculturalAdvice).toBeTruthy();
  });
});
