import { IsString, IsArray, IsOptional } from 'class-validator';

export class SymptomCheckDto {
  @IsString()
  @IsOptional()
  species?: string;

  @IsArray()
  @IsString({ each: true })
  symptoms: string[];

  @IsString()
  @IsOptional()
  imageUrl?: string;
}
