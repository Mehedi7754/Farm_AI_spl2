import { IsString, IsNotEmpty, IsDateString, IsOptional } from 'class-validator';

export class CreateVaccinationDto {
  @IsString()
  @IsNotEmpty()
  livestockId: string;

  @IsString()
  @IsNotEmpty()
  vaccineName: string;

  @IsDateString()
  @IsNotEmpty()
  scheduledDate: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
