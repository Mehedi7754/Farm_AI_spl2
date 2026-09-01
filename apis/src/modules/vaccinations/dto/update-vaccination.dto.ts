import { IsBoolean, IsDateString, IsOptional, IsString } from 'class-validator';

export class UpdateVaccinationDto {
  @IsBoolean()
  @IsOptional()
  isDone?: boolean;

  @IsDateString()
  @IsOptional()
  administeredDate?: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
