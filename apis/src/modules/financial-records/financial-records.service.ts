import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateFinancialRecordDto } from './dto/create-financial-record.dto';

@Injectable()
export class FinancialRecordsService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateFinancialRecordDto) {
    return this.prisma.financialRecord.create({
      data: dto,
      include: { farmer: true },
    });
  }

  async findAll(farmerId?: string) {
    const where = farmerId ? { farmerId } : {};
    return this.prisma.financialRecord.findMany({
      where,
      include: { farmer: true },
      orderBy: { date: 'desc' },
    });
  }

  async findOne(id: string) {
    const record = await this.prisma.financialRecord.findUnique({
      where: { id },
      include: { farmer: true },
    });

    if (!record) throw new NotFoundException(`Financial record with ID ${id} not found`);
    return record;
  }

  async getSummary(farmerId: string) {
    const records = await this.prisma.financialRecord.findMany({
      where: { farmerId },
    });

    let totalIncome = 0;
    let totalExpense = 0;

    records.forEach(r => {
      if (r.type === 'INCOME') totalIncome += r.amount;
      else if (r.type === 'EXPENSE') totalExpense += r.amount;
    });

    return {
      farmerId,
      totalIncome,
      totalExpense,
      netProfit: totalIncome - totalExpense,
      transactionCount: records.length,
    };
  }

  async update(id: string, dto: Partial<CreateFinancialRecordDto>) {
    await this.findOne(id);
    return this.prisma.financialRecord.update({
      where: { id },
      data: dto,
      include: { farmer: true },
    });
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.financialRecord.delete({
      where: { id },
    });
  }
}
