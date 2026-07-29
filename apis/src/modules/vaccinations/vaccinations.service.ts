import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateVaccinationDto } from './dto/create-vaccination.dto';
import { UpdateVaccinationDto } from './dto/update-vaccination.dto';

@Injectable()
export class VaccinationsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateVaccinationDto) {
    return this.prisma.vaccination.create({
      data: {
        livestockId: dto.livestockId,
        vaccineName: dto.vaccineName,
        scheduledDate: new Date(dto.scheduledDate),
        notes: dto.notes,
      },
      include: { livestock: true },
    });
  }

  async findAll(livestockId?: string) {
    const where = livestockId ? { livestockId } : {};
    return this.prisma.vaccination.findMany({
      where,
      include: { livestock: true },
      orderBy: { scheduledDate: 'asc' },
    });
  }

  async findOne(id: string) {
    const record = await this.prisma.vaccination.findUnique({
      where: { id },
      include: { livestock: true },
    });

    if (!record) throw new NotFoundException(`Vaccination record with ID ${id} not found`);
    return record;
  }

  async update(id: string, dto: UpdateVaccinationDto) {
    await this.findOne(id);
    return this.prisma.vaccination.update({
      where: { id },
      data: {
        isDone: dto.isDone,
        administeredDate: dto.administeredDate ? new Date(dto.administeredDate) : undefined,
        notes: dto.notes,
      },
      include: { livestock: true },
    });
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.vaccination.delete({
      where: { id },
    });
  }
}
