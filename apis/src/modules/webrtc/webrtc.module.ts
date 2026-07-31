import { Module } from '@nestjs/common';
import { WebrtcGateway } from './webrtc.gateway';
import { FcmService } from './fcm.service';
import { PrismaService } from '../../database/prisma.service';

@Module({
  providers: [WebrtcGateway, FcmService, PrismaService],
})
export class WebrtcModule {}
