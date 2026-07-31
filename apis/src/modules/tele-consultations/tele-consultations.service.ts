import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { randomUUID } from 'crypto';

@Injectable()
export class TeleConsultationsService {
  constructor(private prisma: PrismaService) {}

  // ── Farmer: Book an appointment ─────────────────────────────────────────

  async book(farmerId: string, vetId: string, slotId: string, notes?: string) {
    const slot = await this.prisma.appointmentSlot.findUnique({ where: { id: slotId } });
    if (!slot) throw new NotFoundException('Slot not found');
    if (slot.isBooked) throw new BadRequestException('This slot is already booked');

    // Resolve vetId (could be User.id or VetProfile.id)
    let realVetId = vetId;
    const profile = await this.prisma.vetProfile.findFirst({
      where: { OR: [{ id: vetId }, { userId: vetId }] },
    });
    if (profile) {
      realVetId = profile.userId;
    }

    if (slot.vetId !== realVetId && slot.vetId !== vetId) {
      throw new BadRequestException('Slot does not belong to this vet');
    }

    const roomId = `room_${randomUUID()}`;

    const [consultation] = await this.prisma.$transaction([
      this.prisma.teleConsultation.create({
        data: {
          farmerId,
          vetId: realVetId,
          slotId,
          scheduledTime: slot.date,
          notes,
          roomId,
          status: 'PENDING',
        },
        include: {
          farmer: { select: { id: true, name: true, phoneNumber: true } },
          vet: { select: { id: true, name: true, phoneNumber: true } },
          slot: true,
        },
      }),
      this.prisma.appointmentSlot.update({ where: { id: slotId }, data: { isBooked: true } }),
    ]);

    return consultation;
  }

  // ── Vet: Accept ──────────────────────────────────────────────────────────

  async accept(id: string) {
    const c = await this._findOne(id);
    if (c.status !== 'PENDING') throw new BadRequestException('Only PENDING consultations can be accepted');
    return this.prisma.teleConsultation.update({
      where: { id },
      data: { status: 'CONFIRMED' },
      include: { farmer: { select: { id: true, name: true } }, vet: { select: { id: true, name: true } }, slot: true },
    });
  }

  // ── Vet: Reject ──────────────────────────────────────────────────────────

  async reject(id: string) {
    const c = await this._findOne(id);
    if (c.slotId) {
      await this.prisma.appointmentSlot.update({ where: { id: c.slotId }, data: { isBooked: false } });
    }
    return this.prisma.teleConsultation.update({
      where: { id },
      data: { status: 'REJECTED' },
      include: { farmer: { select: { id: true, name: true } }, vet: { select: { id: true, name: true } } },
    });
  }

  // ── Complete ─────────────────────────────────────────────────────────────

  async complete(id: string, prescription?: string) {
    return this.prisma.teleConsultation.update({
      where: { id },
      data: { status: 'COMPLETED', prescription, callStatus: 'ENDED' },
      include: { farmer: { select: { id: true, name: true } }, vet: { select: { id: true, name: true } } },
    });
  }

  // ── Start call ───────────────────────────────────────────────────────────

  async startCall(id: string) {
    return this.prisma.teleConsultation.update({
      where: { id },
      data: { callStatus: 'IN_PROGRESS', status: 'IN_PROGRESS' },
    });
  }

  // ── My consultations ─────────────────────────────────────────────────────

  async findMyConsultations(userId: string, role: 'FARMER' | 'VET') {
    const where = role === 'FARMER' ? { farmerId: userId } : { vetId: userId };
    return this.prisma.teleConsultation.findMany({
      where,
      include: {
        farmer: { select: { id: true, name: true, phoneNumber: true } },
        vet: { select: { id: true, name: true, phoneNumber: true } },
        slot: true,
      },
      orderBy: { scheduledTime: 'asc' },
    });
  }

  async findAll(farmerId?: string, vetId?: string) {
    const where: any = {};
    if (farmerId) where.farmerId = farmerId;
    if (vetId) where.vetId = vetId;
    return this.prisma.teleConsultation.findMany({
      where,
      include: { farmer: true, vet: true, slot: true },
      orderBy: { scheduledTime: 'asc' },
    });
  }

  async findOne(id: string) {
    return this._findOne(id);
  }

  async update(id: string, dto: any) {
    await this._findOne(id);
    return this.prisma.teleConsultation.update({ where: { id }, data: dto, include: { farmer: true, vet: true } });
  }

  async cancel(id: string) {
    const c = await this._findOne(id);
    if (c.slotId) {
      await this.prisma.appointmentSlot.update({ where: { id: c.slotId }, data: { isBooked: false } });
    }
    return this.prisma.teleConsultation.update({ where: { id }, data: { status: 'CANCELLED' } });
  }

  private async _findOne(id: string) {
    const c = await this.prisma.teleConsultation.findUnique({
      where: { id },
      include: { farmer: { select: { id: true, name: true } }, vet: { select: { id: true, name: true } }, slot: true },
    });
    if (!c) throw new NotFoundException(`Consultation ${id} not found`);
    return c;
  }
}
