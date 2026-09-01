import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { PrismaModule } from '../../database/prisma.module';
import { FcmService } from '../webrtc/fcm.service';

@Module({
  imports: [PrismaModule],
  controllers: [ChatController],
  providers: [ChatService, FcmService],
})
export class ChatModule {}
