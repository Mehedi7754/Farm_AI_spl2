import { Controller, Post, Body, UseInterceptors, UploadedFile } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { AiToolsService } from './ai-tools.service';
import { VoiceChatDto } from './dto/voice-chat.dto';
import { SymptomCheckDto } from './dto/symptom-check.dto';

@Controller('ai-tools')
export class AiToolsController {
  constructor(private readonly aiToolsService: AiToolsService) {}

  @Post('voice-chat')
  voiceChat(@Body() dto: VoiceChatDto) {
    return this.aiToolsService.voiceChat(dto);
  }

  @Post('symptom-check')
  symptomCheck(@Body() dto: SymptomCheckDto) {
    return this.aiToolsService.analyzeSymptoms(dto);
  }

  @Post('transcribe')
  @UseInterceptors(FileInterceptor('file'))
  transcribe(@UploadedFile() file: any) {
    const buffer = file?.buffer || Buffer.from('mock audio');
    const name = file?.originalname || 'audio.mp3';
    return this.aiToolsService.transcribeAudio(buffer, name);
  }
}
