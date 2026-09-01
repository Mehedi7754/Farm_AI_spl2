import { Module } from '@nestjs/common';
import { VetProfilesService } from './vet-profiles.service';
import { VetProfilesController } from './vet-profiles.controller';

@Module({
  controllers: [VetProfilesController],
  providers: [VetProfilesService],
  exports: [VetProfilesService],
})
export class VetProfilesModule {}
