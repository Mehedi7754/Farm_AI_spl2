import { Module } from '@nestjs/common';
import { TeleConsultationsService } from './tele-consultations.service';
import { TeleConsultationsController } from './tele-consultations.controller';
import { WebrtcModule } from '../webrtc/webrtc.module';

@Module({
  imports: [WebrtcModule],
  controllers: [TeleConsultationsController],
  providers: [TeleConsultationsService],
  exports: [TeleConsultationsService],
})
export class TeleConsultationsModule {}
