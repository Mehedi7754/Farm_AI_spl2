import { IsNumber, IsNotEmpty, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class FindVetsDto {
  @Type(() => Number)
  @IsNotEmpty({ message: 'Latitude is required — send your real GPS location' })
  @IsNumber()
  lat: number;

  @Type(() => Number)
  @IsNotEmpty({ message: 'Longitude is required — send your real GPS location' })
  @IsNumber()
  lng: number;

  @Type(() => Number)
  @IsOptional()
  @IsNumber()
  radius?: number;
}
