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

  private checkIsOnline(updatedAt: Date | null): boolean {
    if (!updatedAt) return false;
    const diffSeconds = (Date.now() - new Date(updatedAt).getTime()) / 1000;
    return diffSeconds <= 900; // Online if updated in past 15 minutes
  }

  private formatTimeAgo(date: Date | null): string {
    if (!date) return 'কখনো সক্রিয় হয়নি';
    const diffMs = Date.now() - new Date(date).getTime();
    const diffSec = Math.max(0, Math.floor(diffMs / 1000));
    if (diffSec < 60) return 'এইমাত্র';
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) return `${diffMin} মিনিট আগে`;
    const diffHour = Math.floor(diffMin / 60);
    if (diffHour < 24) return `${diffHour} ঘণ্টা আগে`;
    const diffDay = Math.floor(diffHour / 24);
    return `${diffDay} দিন আগে`;
  }

  private formatCollarResponse(collar: any) {
    if (!collar) return null;
    const isOnline = this.checkIsOnline(collar.updatedAt);
    const lastActiveAgo = this.formatTimeAgo(collar.updatedAt);

    // Only use location records that were recorded within the last 24 hours
    // (filters out any seeded/fake future-dated records)
    const now = Date.now();
    const realLocations = (collar.locations || []).filter((l: any) => {
      const recorded = new Date(l.recordedAt).getTime();
      return recorded <= now && (now - recorded) < 86400_000; // max 24h old
    });
    const latestLoc = realLocations[0] ?? null;

    return {
      id: collar.id,
      livestockId: collar.livestockId,
      deviceCode: collar.deviceCode,
      pairingPin: collar.pairingPin,
      firmwareVersion: collar.firmwareVersion,
      batteryLevel: collar.batteryLevel ?? null,
      isOnline,
      isSolarCharging: collar.isSolarCharging,
      isBuzzerActive: collar.isBuzzerActive,
      isLedActive: collar.isLedActive,
      signalStrength: collar.signalStrength ?? null,
      // Biometric fields — null if device hasn't pushed real data
      lastHeartRate: null,
      lastBodyTemp: null,
      lastStepCount: null,
      // GPS position — only from real device pushes
      lastLatitude: collar.lastLatitude ?? null,
      lastLongitude: collar.lastLongitude ?? null,
      geofenceRadius: collar.geofenceRadius ?? 150,
      safeZoneLat: collar.safeZoneLat ?? null,
      safeZoneLng: collar.safeZoneLng ?? null,
      createdAt: collar.createdAt,
      updatedAt: collar.updatedAt,
      lastActive: collar.updatedAt ? new Date(collar.updatedAt).toISOString() : null,
      lastActiveAgo,
      livestock: collar.livestock ?? null,
      // GPS telemetry — strictly from real device location pushes only
      speed: latestLoc?.speed ?? null,
      altitude: latestLoc?.altitude ?? null,
      satellites: latestLoc?.satellites ?? null,
      fixQuality: latestLoc?.fixQuality ?? null,
      course: latestLoc?.course ?? null,
      // GPS breadcrumb trail — only real records
      trail: realLocations.map((l: any) => ({
        latitude: l.latitude,
        longitude: l.longitude,
        speed: l.speed ?? null,
        altitude: l.altitude ?? null,
        recordedAt: l.recordedAt,
      })),
    };
  }

  async findAll() {
    const collars = await this.prisma.smartCollar.findMany({
      include: {
        livestock: true,
        locations: {
          orderBy: { recordedAt: 'desc' },
          take: 15,
        },
      },
    });
    return collars.map((c) => this.formatCollarResponse(c));
  }

  async findOne(id: string) {
    const collar = await this.prisma.smartCollar.findUnique({
      where: { id },
      include: {
        livestock: true,
        locations: {
          orderBy: { recordedAt: 'desc' },
          take: 20,
        },
      },
    });

    if (!collar) throw new NotFoundException(`Smart Collar with ID ${id} not found`);
    return this.formatCollarResponse(collar);
  }

  async findByLivestock(livestockId: string) {
    const collar = await this.prisma.smartCollar.findUnique({
      where: { livestockId },
      include: {
        livestock: true,
        locations: {
          orderBy: { recordedAt: 'desc' },
          take: 20,
        },
      },
    });

    if (!collar) throw new NotFoundException(`Smart Collar for Livestock ${livestockId} not found`);
    return this.formatCollarResponse(collar);
  }

  async findByDeviceCode(deviceCode: string) {
    const collar = await this.prisma.smartCollar.findUnique({
      where: { deviceCode },
      include: {
        livestock: true,
        locations: {
          orderBy: { recordedAt: 'desc' },
          take: 20,
        },
      },
    });

    if (!collar) throw new NotFoundException(`Smart Collar with device code ${deviceCode} not found`);
    
    return this.formatCollarResponse(collar);
  }

  async update(id: string, dto: any) {
    await this.findOne(id);
    return this.prisma.smartCollar.update({
      where: { id },
      data: dto,
      include: { livestock: true },
    });
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
    const rawCollar = await this.prisma.smartCollar.findUnique({ where: { id } });
    if (!rawCollar) throw new NotFoundException(`Smart Collar with ID ${id} not found`);
    return {
      success: true,
      deviceId: rawCollar.deviceCode,
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
    // Use direct DB lookup (not formatted response) to avoid null type issues
    const rawCollar = await this.prisma.smartCollar.findUnique({
      where: { deviceCode: dto.deviceCode },
    });
    if (!rawCollar) throw new NotFoundException(`Smart Collar with device code ${dto.deviceCode} not found`);

    // Parse date/time from ESP32 GPS format (DD/MM/YYYY + HH:MM:SS)
    let recordedAt = new Date();
    if (dto.date && dto.time) {
      const [day, month, year] = dto.date.split('/');
      const [hours, minutes, seconds] = dto.time.split(':');
      const parsed = new Date(
        Date.UTC(
          parseInt(year),
          parseInt(month) - 1,
          parseInt(day),
          parseInt(hours),
          parseInt(minutes),
          parseInt(seconds),
        ),
      );
      // Sanity check: reject future-dated GPS timestamps (ESP32 parse errors)
      if (parsed.getTime() <= Date.now()) {
        recordedAt = parsed;
      }
    }

    // Store location entry in history
    const location = await this.prisma.collarLocation.create({
      data: {
        collarId: rawCollar.id,
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
      where: { id: rawCollar.id },
      data: {
        lastLatitude: dto.latitude,
        lastLongitude: dto.longitude,
        isOnline: true,
      },
    });

    return {
      success: true,
      locationId: location.id,
      collarId: rawCollar.id,
      deviceCode: rawCollar.deviceCode,
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
