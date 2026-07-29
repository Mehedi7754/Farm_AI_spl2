import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateSmartCollarDto } from './dto/create-smart-collar.dto';
import { UpdateTelemetryDto } from './dto/update-telemetry.dto';

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
}
