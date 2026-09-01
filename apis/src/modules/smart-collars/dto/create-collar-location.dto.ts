import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsInt,
  IsDateString,
} from 'class-validator';

export class CreateCollarLocationDto {
  @IsString()
  @IsNotEmpty()
  deviceCode: string;

  @IsNumber()
  latitude: number;

  @IsNumber()
  longitude: number;

  @IsNumber()
  @IsOptional()
  altitude?: number;

  @IsNumber()
  @IsOptional()
  speed?: number;

  @IsNumber()
  @IsOptional()
  course?: number;

  @IsInt()
  @IsOptional()
  satellites?: number;

  @IsString()
  @IsOptional()
  fixQuality?: string;

  @IsString()
  @IsOptional()
  date?: string; // DD/MM/YYYY from ESP32

  @IsString()
  @IsOptional()
  time?: string; // HH:MM:SS UTC from ESP32
}
