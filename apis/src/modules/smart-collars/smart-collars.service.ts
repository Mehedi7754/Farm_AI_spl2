import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateSmartCollarDto } from './dto/create-smart-collar.dto';
import { UpdateTelemetryDto } from './dto/update-telemetry.dto';
import { CreateCollarLocationDto } from './dto/create-collar-location.dto';

@Injectable()
export class SmartCollarsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateSmartCollarDto) {
    return this.prisma.smartCollar.create({
      data: dto,
      include: { livestock: true },
    });
  }

  async findAll() {
    return this.prisma.smartCollar.findMany({
      include: { livestock: true },
    });
  }

  async findOne(id: string) {
    const collar = await this.prisma.smartCollar.findUnique({
      where: { id },
      include: { livestock: true },
    });

    if (!collar) throw new NotFoundException(`Smart Collar with ID ${id} not found`);
    return collar;
  }

  async findByLivestock(livestockId: string) {
    const collar = await this.prisma.smartCollar.findUnique({
      where: { livestockId },
      include: { livestock: true },
    });

    if (!collar) throw new NotFoundException(`Smart Collar for Livestock ${livestockId} not found`);
    return collar;
  }

  async findByDeviceCode(deviceCode: string) {
    const collar = await this.prisma.smartCollar.findUnique({
      where: { deviceCode },
      include: { livestock: true },
    });

    if (!collar) throw new NotFoundException(`Smart Collar with device code ${deviceCode} not found`);
    return collar;
  }

  async updateTelemetry(id: string, dto: UpdateTelemetryDto) {
    await this.findOne(id);
    return this.prisma.smartCollar.update({
      where: { id },
      data: dto,
      include: { livestock: true },
    });
  }

  async triggerLedAlert(id: string, color: string = 'RED') {
    const collar = await this.findOne(id);
    return {
      success: true,
      deviceId: collar.deviceCode,
      action: 'LED_ALERT_TRIGGERED',
      color,
      timestamp: new Date().toISOString(),
    };
  }

  // ── GPS Location Methods ──────────────────────────────────────────

  /**
   * ESP32 hits this endpoint to log a GPS location ping.
   * Looks up the collar by deviceCode, stores the location,
   * and updates the collar's lastLatitude/lastLongitude.
   */
  async createLocation(dto: CreateCollarLocationDto) {
    const collar = await this.findByDeviceCode(dto.deviceCode);

    // Parse date/time from ESP32 GPS format (DD/MM/YYYY + HH:MM:SS)
    let recordedAt = new Date();
    if (dto.date && dto.time) {
      const [day, month, year] = dto.date.split('/');
      const [hours, minutes, seconds] = dto.time.split(':');
      recordedAt = new Date(
        Date.UTC(
          parseInt(year),
          parseInt(month) - 1,
          parseInt(day),
          parseInt(hours),
          parseInt(minutes),
          parseInt(seconds),
        ),
      );
    }

    // Store location entry in history
    const location = await this.prisma.collarLocation.create({
      data: {
        collarId: collar.id,
        latitude: dto.latitude,
        longitude: dto.longitude,
        altitude: dto.altitude,
        speed: dto.speed,
        course: dto.course,
        satellites: dto.satellites,
        fixQuality: dto.fixQuality,
        recordedAt,
      },
    });

    // Update collar with latest position + mark online
    await this.prisma.smartCollar.update({
      where: { id: collar.id },
      data: {
        lastLatitude: dto.latitude,
        lastLongitude: dto.longitude,
        isOnline: true,
      },
    });

    return {
      success: true,
      locationId: location.id,
      collarId: collar.id,
      deviceCode: collar.deviceCode,
      latitude: dto.latitude,
      longitude: dto.longitude,
      recordedAt: recordedAt.toISOString(),
    };
  }

  /**
   * Get location history for a collar (for map trail).
   * Default last 100 points, sorted newest first.
   */
  async getLocationHistory(collarId: string, limit: number = 100) {
    await this.findOne(collarId);

    return this.prisma.collarLocation.findMany({
      where: { collarId },
      orderBy: { recordedAt: 'desc' },
      take: limit,
    });
  }

  /**
   * Get latest location for a collar (for current position on map).
   */
  async getLatestLocation(collarId: string) {
    await this.findOne(collarId);

    const location = await this.prisma.collarLocation.findFirst({
      where: { collarId },
      orderBy: { recordedAt: 'desc' },
    });

    if (!location) {
      throw new NotFoundException(`No location data for collar ${collarId}`);
    }

    return location;
  }

  /**
   * Get all collars with their latest location (for map overview).
   */
  async getAllWithLatestLocation() {
    const collars = await this.prisma.smartCollar.findMany({
      include: {
        livestock: true,
      },
      where: {
        lastLatitude: { not: null },
        lastLongitude: { not: null },
      },
    });

    return collars.map((collar) => ({
      id: collar.id,
      deviceCode: collar.deviceCode,
      livestockId: collar.livestockId,
      livestock: collar.livestock,
      batteryLevel: collar.batteryLevel,
      isOnline: collar.isOnline,
      latitude: collar.lastLatitude,
      longitude: collar.lastLongitude,
      updatedAt: collar.updatedAt,
    }));
  }

  /**
   * Get location history within a date range (for filtered map trails).
   */
  async getLocationHistoryByDateRange(
    collarId: string,
    from: Date,
    to: Date,
  ) {
    await this.findOne(collarId);

    return this.prisma.collarLocation.findMany({
      where: {
        collarId,
        recordedAt: {
          gte: from,
          lte: to,
        },
      },
      orderBy: { recordedAt: 'asc' },
    });
  }
}
