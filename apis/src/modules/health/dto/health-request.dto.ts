import { IsOptional, IsString } from 'class-validator';

export class HealthRequestDto {
  @IsOptional()
  @IsString()
  source?: string;
}
