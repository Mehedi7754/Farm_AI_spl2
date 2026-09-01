import { IsString, IsNotEmpty, IsInt, IsOptional, IsBoolean, IsNumber } from 'class-validator';

export class CreateSmartCollarDto {
  @IsString()
  @IsNotEmpty()
  livestockId: string;

  @IsString()
  @IsNotEmpty()
  deviceCode: string;

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
