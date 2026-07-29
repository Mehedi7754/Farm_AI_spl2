import { IsNumber, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class GetWeatherDto {
  @Type(() => Number)
  @IsNumber()
  lat: number;

  @Type(() => Number)
  @IsNumber()
  lng: number;
}
