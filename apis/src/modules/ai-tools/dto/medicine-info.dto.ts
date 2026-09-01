import { IsString, IsOptional } from 'class-validator';

export class MedicineInfoDto {
  @IsString()
  query: string;

  @IsString()
  @IsOptional()
  species?: string;

  @IsString()
  @IsOptional()
  symptoms?: string;

  @IsString()
  @IsOptional()
  disease?: string;
}
