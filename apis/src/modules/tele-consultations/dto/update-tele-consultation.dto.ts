import { IsString, IsOptional } from 'class-validator';

export class UpdateTeleConsultationDto {
  @IsString()
  @IsOptional()
  status?: string;

  @IsString()
  @IsOptional()
  prescription?: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
