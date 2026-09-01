import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateLivestockDto } from './dto/create-livestock.dto';
import { UpdateLivestockDto } from './dto/update-livestock.dto';
import { Livestock } from '@prisma/client';

@Injectable()
export class LivestockService {
  constructor(private prisma: PrismaService) {}

  async create(createLivestockDto: CreateLivestockDto): Promise<Livestock> {
    return this.prisma.livestock.create({
      data: createLivestockDto,
    });
  }

  async findAll(farmerId?: string): Promise<any[]> {
    return this.prisma.livestock.findMany({
      where: farmerId ? { farmerId } : undefined,
      include: { smartCollar: true },
    });
  }

  async findOne(id: string): Promise<any> {
    const livestock = await this.prisma.livestock.findUnique({
      where: { id },
      include: { smartCollar: true },
    });

    if (!livestock) {
      throw new NotFoundException(`Livestock with ID ${id} not found`);
    }

    return livestock;
  }

  async update(id: string, updateLivestockDto: UpdateLivestockDto): Promise<Livestock> {
    await this.findOne(id);

    const updated = await this.prisma.livestock.update({
      where: { id },
      data: updateLivestockDto,
    });

    if (updateLivestockDto.status === 'SOLD' || updateLivestockDto.status === 'DECEASED') {
      // Unassign SmartCollar so hardware can be reused
      await this.prisma.smartCollar.updateMany({
        where: { livestockId: id },
        data: { livestockId: null },
      });
      // Delete pending vaccinations
      await this.prisma.vaccination.deleteMany({
        where: { livestockId: id, isDone: false },
      });
    }

    return updated;
  }

  async remove(id: string): Promise<Livestock> {
    await this.findOne(id);

    // Explicitly unassign collar first before deleting livestock
    await this.prisma.smartCollar.updateMany({
      where: { livestockId: id },
      data: { livestockId: null },
    });

    return this.prisma.livestock.delete({
      where: { id },
    });
  }
}
