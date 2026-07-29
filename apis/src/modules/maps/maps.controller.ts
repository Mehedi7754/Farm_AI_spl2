import { Controller, Get, Query } from '@nestjs/common';
import { MapsService } from './maps.service';
import { FindVetsDto } from './dto/find-vets.dto';

@Controller('maps')
export class MapsController {
  constructor(private readonly mapsService: MapsService) {}

  @Get('nearby-vets')
  findNearbyVets(@Query() dto: FindVetsDto) {
    return this.mapsService.findNearbyVets(dto);
  }
}
