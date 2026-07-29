import { IsInt, IsOptional, IsBoolean, IsNumber } from 'class-validator';

export class UpdateTelemetryDto {
  @IsInt()
  @IsOptional()
  batteryLevel?: number;

  @IsBoolean()
  @IsOptional()
  isOnline?: boolean;

  @IsNumber()
  @IsOptional()
  lastHeartRate?: number;

  @IsNumber()
  @IsOptional()
  lastBodyTemp?: number;

  @IsInt()
  @IsOptional()
  lastStepCount?: number;
}
