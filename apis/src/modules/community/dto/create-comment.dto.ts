import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateCommentDto {
  @IsString()
  @IsOptional()
  authorId?: string;

  @IsString()
  @IsNotEmpty()
  content: string;
}
