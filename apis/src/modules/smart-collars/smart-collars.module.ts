import { Module } from '@nestjs/common';
import { SmartCollarsService } from './smart-collars.service';
import { SmartCollarsController } from './smart-collars.controller';

@Module({
  controllers: [SmartCollarsController],
  providers: [SmartCollarsService],
  exports: [SmartCollarsService],
})
export class SmartCollarsModule {}
