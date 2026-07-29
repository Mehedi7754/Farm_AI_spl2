import { Controller, Get, Post, Body, Patch, Param } from '@nestjs/common';
import { SmartCollarsService } from './smart-collars.service';
import { CreateSmartCollarDto } from './dto/create-smart-collar.dto';
import { UpdateTelemetryDto } from './dto/update-telemetry.dto';

@Controller('smart-collars')
export class SmartCollarsController {
  constructor(private readonly smartCollarsService: SmartCollarsService) {}

  @Post()
  create(@Body() dto: CreateSmartCollarDto) {
    return this.smartCollarsService.create(dto);
  }

  @Get()
  findAll() {
    return this.smartCollarsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.smartCollarsService.findOne(id);
  }

  @Get('livestock/:livestockId')
  findByLivestock(@Param('livestockId') livestockId: string) {
    return this.smartCollarsService.findByLivestock(livestockId);
  }

  @Patch(':id/telemetry')
  updateTelemetry(@Param('id') id: string, @Body() dto: UpdateTelemetryDto) {
    return this.smartCollarsService.updateTelemetry(id, dto);
  }

  @Post(':id/led-alert')
  triggerLedAlert(@Param('id') id: string, @Body('color') color?: string) {
    return this.smartCollarsService.triggerLedAlert(id, color);
  }
}
