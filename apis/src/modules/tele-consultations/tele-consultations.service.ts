import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateTeleConsultationDto } from './dto/create-tele-consultation.dto';
import { UpdateTeleConsultationDto } from './dto/update-tele-consultation.dto';

@Injectable()
export class TeleConsultationsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateTeleConsultationDto) {
    return this.prisma.teleConsultation.create({
      data: {
        farmerId: dto.farmerId,
        vetId: dto.vetId,
        scheduledTime: new Date(dto.scheduledTime),
        notes: dto.notes,
        status: 'PENDING',
      },
      include: { farmer: true, vet: true },
    });
  }

  async findAll(farmerId?: string, vetId?: string) {
    const where: any = {};
    if (farmerId) where.farmerId = farmerId;
    if (vetId) where.vetId = vetId;

    return this.prisma.teleConsultation.findMany({
      where,
      include: { farmer: true, vet: true },
      orderBy: { scheduledTime: 'asc' },
    });
  }

  async findOne(id: string) {
    const consultation = await this.prisma.teleConsultation.findUnique({
      where: { id },
      include: { farmer: true, vet: true },
    });

    if (!consultation) throw new NotFoundException(`Consultation with ID ${id} not found`);
    return consultation;
  }

  async update(id: string, dto: UpdateTeleConsultationDto) {
    await this.findOne(id);
    return this.prisma.teleConsultation.update({
      where: { id },
      data: dto,
      include: { farmer: true, vet: true },
    });
  }

  async cancel(id: string) {
    await this.findOne(id);
    return this.prisma.teleConsultation.update({
      where: { id },
      data: { status: 'CANCELLED' },
    });
  }
}
