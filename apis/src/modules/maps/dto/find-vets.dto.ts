import { IsNumber, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class FindVetsDto {
  @Type(() => Number)
  @IsOptional()
  @IsNumber()
  lat?: number;

  @Type(() => Number)
  @IsOptional()
  @IsNumber()
  lng?: number;

  @Type(() => Number)
  @IsOptional()
  @IsNumber()
  radius?: number;
}
