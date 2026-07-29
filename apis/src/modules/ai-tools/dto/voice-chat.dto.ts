import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class VoiceChatDto {
  @IsString()
  @IsNotEmpty()
  message: string;

  @IsString()
  @IsOptional()
  language?: string; // 'bn' for Bengali, 'en' for English
}
