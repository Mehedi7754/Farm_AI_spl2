import { IsString, IsNotEmpty, IsDateString, IsOptional } from 'class-validator';

export class CreateTeleConsultationDto {
  @IsString()
  @IsNotEmpty()
  farmerId: string;

  @IsString()
  @IsNotEmpty()
  vetId: string;

  @IsDateString()
  @IsNotEmpty()
  scheduledTime: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
