import { IsString, IsNotEmpty, IsDateString, IsNumber, IsEnum, IsOptional } from 'class-validator';
import { AnimalStatus, Gender } from '@prisma/client';

export class CreateLivestockDto {
  @IsString()
  @IsNotEmpty()
  farmerId: string;

  @IsString()
  @IsNotEmpty()
  species: string;

  @IsString()
  @IsNotEmpty()
  breed: string;

  @IsDateString()
  @IsNotEmpty()
  dateOfBirth: Date;

  @IsEnum(Gender)
  @IsNotEmpty()
  gender: Gender;

  @IsNumber()
  @IsNotEmpty()
  weight: number;

  @IsEnum(AnimalStatus)
  @IsOptional()
  status?: AnimalStatus;
}
