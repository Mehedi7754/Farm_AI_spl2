import { Module } from '@nestjs/common';
import { HealthHttpController } from './controllers/health.http.controller';
import { HealthMessageController } from './controllers/health.message.controller';
import { HealthService } from './services/health.service';

@Module({
  controllers: [HealthHttpController, HealthMessageController],
  providers: [HealthService],
})
export class HealthModule {}
