import { IsString, IsNotEmpty, IsNumber, IsOptional, IsArray, IsBoolean, Min, Max } from 'class-validator';

export class CreateVetProfileDto {
  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsString()
  @IsNotEmpty()
  licenseNumber: string;

  @IsString()
  @IsNotEmpty()
  specialization: string;

  @IsNumber()
  @IsOptional()
  experienceYears?: number;

  @IsNumber()
  @IsOptional()
  consultationFee?: number;

  @IsString()
  @IsOptional()
  availableFrom?: string;

  @IsString()
  @IsOptional()
  availableTo?: string;

  @IsArray()
  @IsOptional()
  availableDays?: string[];

  @IsString()
  @IsOptional()
  bio?: string;

  @IsString()
  @IsOptional()
  profileImageUrl?: string;

  @IsNumber()
  @IsOptional()
  latitude?: number;

  @IsNumber()
  @IsOptional()
  longitude?: number;

  @IsString()
  @IsOptional()
  district?: string;
}
