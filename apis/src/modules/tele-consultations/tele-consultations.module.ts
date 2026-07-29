import { Module } from '@nestjs/common';
import { TeleConsultationsService } from './tele-consultations.service';
import { TeleConsultationsController } from './tele-consultations.controller';

@Module({
  controllers: [TeleConsultationsController],
  providers: [TeleConsultationsService],
  exports: [TeleConsultationsService],
})
export class TeleConsultationsModule {}
