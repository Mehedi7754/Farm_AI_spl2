import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @IsOptional()
  authorId?: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  content: string;

  @IsString()
  @IsOptional()
  category?: string; // e.g. "HEALTH", "FEEDING", "EQUIPMENT", "GENERAL"

  @IsString()
  @IsOptional()
  imageUrl?: string;
}
