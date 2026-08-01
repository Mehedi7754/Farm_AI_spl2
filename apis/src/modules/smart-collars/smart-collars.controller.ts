import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Query,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { SmartCollarsService } from './smart-collars.service';
import { CreateSmartCollarDto } from './dto/create-smart-collar.dto';
import { UpdateTelemetryDto } from './dto/update-telemetry.dto';
import { CreateCollarLocationDto } from './dto/create-collar-location.dto';

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

  @Get('locations/all')
  getAllWithLatestLocation() {
    return this.smartCollarsService.getAllWithLatestLocation();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.smartCollarsService.findOne(id);
  }

  @Get('livestock/:livestockId')
  findByLivestock(@Param('livestockId') livestockId: string) {
    return this.smartCollarsService.findByLivestock(livestockId);
  }

  @Get('device/:deviceCode')
  findByDeviceCode(@Param('deviceCode') deviceCode: string) {
    return this.smartCollarsService.findByDeviceCode(deviceCode);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: any) {
    return this.smartCollarsService.update(id, dto);
  }

  @Patch(':id/telemetry')
  updateTelemetry(@Param('id') id: string, @Body() dto: UpdateTelemetryDto) {
    return this.smartCollarsService.updateTelemetry(id, dto);
  }

  @Post(':id/led-alert')
  triggerLedAlert(@Param('id') id: string, @Body('color') color?: string) {
    return this.smartCollarsService.triggerLedAlert(id, color);
  }

  // ── ESP32 GPS Location Endpoints ────────────────────────────────

  /**
   * POST /smart-collars/location
   * ESP32 hits this endpoint with GPS data.
   * Body: { deviceCode, latitude, longitude, altitude, speed, course, satellites, fixQuality, date, time }
   */
  @Post('location')
  createLocation(@Body() dto: CreateCollarLocationDto) {
    return this.smartCollarsService.createLocation(dto);
  }

  /**
   * GET /smart-collars/:id/locations?limit=100
   * App fetches location history for map trail.
   */
  @Get(':id/locations')
  getLocationHistory(
    @Param('id') id: string,
    @Query('limit', new DefaultValuePipe(100), ParseIntPipe) limit: number,
  ) {
    return this.smartCollarsService.getLocationHistory(id, limit);
  }

  /**
   * GET /smart-collars/:id/locations/latest
   * App fetches current position for a collar.
   */
  @Get(':id/locations/latest')
  getLatestLocation(@Param('id') id: string) {
    return this.smartCollarsService.getLatestLocation(id);
  }

  /**
   * GET /smart-collars/:id/locations/range?from=2026-07-01&to=2026-07-31
   * App fetches location trail within a date range.
   */
  @Get(':id/locations/range')
  getLocationHistoryByDateRange(
    @Param('id') id: string,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.smartCollarsService.getLocationHistoryByDateRange(
      id,
      new Date(from),
      new Date(to),
    );
  }
}
