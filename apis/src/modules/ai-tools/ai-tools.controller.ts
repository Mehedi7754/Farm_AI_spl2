import { Controller, Post, Body, UseInterceptors, UploadedFile, Res } from '@nestjs/common';
import { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { AiToolsService } from './ai-tools.service';
import { VoiceChatDto } from './dto/voice-chat.dto';
import { SymptomCheckDto } from './dto/symptom-check.dto';
import { MedicineInfoDto } from './dto/medicine-info.dto';

@Controller('ai-tools')
export class AiToolsController {
  constructor(private readonly aiToolsService: AiToolsService) {}

  @Post('voice-chat')
  voiceChat(@Body() dto: VoiceChatDto) {
    return this.aiToolsService.voiceChat(dto);
  }

  @Post('voice-chat-stream')
  voiceChatStream(@Body() dto: VoiceChatDto, @Res() res: any) {
    return this.aiToolsService.voiceChatStream(dto, res);
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

  @Post('medicine-info')
  getMedicineInfo(@Body() dto: MedicineInfoDto) {
    return this.aiToolsService.getMedicineInfo(dto);
  }

  @Post('voice-to-voice')
  @UseInterceptors(FileInterceptor('file'))
  async voiceToVoice(@UploadedFile() file: any) {
    const buffer = file?.buffer || Buffer.from('');
    const name = file?.originalname || 'audio.mp3';
    return this.aiToolsService.voiceToVoice(buffer, name);
  }
}
