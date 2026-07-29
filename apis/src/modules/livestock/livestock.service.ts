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

  async findAll(farmerId?: string): Promise<Livestock[]> {
    return this.prisma.livestock.findMany({
      where: farmerId ? { farmerId } : undefined,
    });
  }

  async findOne(id: string): Promise<Livestock> {
    const livestock = await this.prisma.livestock.findUnique({
      where: { id },
    });

    if (!livestock) {
      throw new NotFoundException(`Livestock with ID ${id} not found`);
    }

    return livestock;
  }

  async update(id: string, updateLivestockDto: UpdateLivestockDto): Promise<Livestock> {
    await this.findOne(id);

    return this.prisma.livestock.update({
      where: { id },
      data: updateLivestockDto,
    });
  }

  async remove(id: string): Promise<Livestock> {
    await this.findOne(id);

    return this.prisma.livestock.delete({
      where: { id },
    });
  }
}
