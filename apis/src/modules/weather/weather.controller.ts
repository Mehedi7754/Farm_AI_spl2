import { Controller, Get, Query, Param, Res } from '@nestjs/common';
import type { Response } from 'express';
import { WeatherService } from './weather.service';
import { GetWeatherDto } from './dto/get-weather.dto';

@Controller('weather')
export class WeatherController {
  constructor(private readonly weatherService: WeatherService) {}

  @Get()
  getWeather(@Query() dto: GetWeatherDto) {
    return this.weatherService.getWeatherForecast(dto);
  }

  @Get('tile/:layer/:z/:x/:y')
  async getTile(
    @Param('layer') layer: string,
    @Param('z') z: string,
    @Param('x') x: string,
    @Param('y') y: string,
    @Res() res: Response
  ) {
    return this.weatherService.getWeatherMapTile(layer, z, x, y, res);
  }
}
