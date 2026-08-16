import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { FcmService } from '../webrtc/fcm.service';
import { randomUUID } from 'crypto';

@Injectable()
export class TeleConsultationsService {
  private readonly logger = new Logger(TeleConsultationsService.name);

  constructor(
    private prisma: PrismaService,
    private fcmService: FcmService,
  ) {}

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

    let scheduledTime = slot.date;
    if (slot.startTime) {
      try {
        const [hours, minutes] = slot.startTime.split(':').map(Number);
        if (!isNaN(hours) && !isNaN(minutes)) {
          const d = new Date(slot.date);
          d.setHours(hours, minutes, 0, 0);
          scheduledTime = d;
        }
      } catch (_) {}
    }

    const roomId = `room_${randomUUID()}`;

    const [consultation] = await this.prisma.$transaction([
      this.prisma.teleConsultation.create({
        data: {
          farmerId,
          vetId: realVetId,
          slotId,
          scheduledTime,
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

    // Send push notification to Vet asynchronously
    this._notifyVetNewBooking(consultation.id, farmerId, realVetId, consultation.farmer?.name).catch((e) => {
      this.logger.error('Failed to notify vet of new booking', e);
    });

    return consultation;
  }

  private async _notifyVetNewBooking(consultationId: string, farmerId: string, vetId: string, farmerName?: string) {
    const vet = await this.prisma.user.findUnique({ where: { id: vetId }, select: { fcmToken: true } });
    if (vet?.fcmToken) {
      const name = farmerName || 'একজন কৃষক';
      await this.fcmService.sendGenericNotification({
        fcmToken: vet.fcmToken,
        title: '📅 নতুন অ্যাপয়েন্টমেন্ট বুকিং',
        body: `${name} আপনার সাথে একটি কনসালটেশন অ্যাপয়েন্টমেন্ট বুক করেছেন।`,
        data: {
          type: 'RESERVATION_BOOKED',
          consultationId,
          farmerId,
          farmerName: name,
        },
        channelId: 'chat_messages',
      });
    }
  }

  private async _notifyFarmerStatusChange(consultationId: string, farmerId: string, vetName: string, status: 'CONFIRMED' | 'REJECTED') {
    const farmer = await this.prisma.user.findUnique({ where: { id: farmerId }, select: { fcmToken: true } });
    if (farmer?.fcmToken) {
      const isAccepted = status === 'CONFIRMED';
      await this.fcmService.sendGenericNotification({
        fcmToken: farmer.fcmToken,
        title: isAccepted ? '✅ অ্যাপয়েন্টমেন্ট নিশ্চিত হয়েছে' : '❌ অ্যাপয়েন্টমেন্ট বাতিল',
        body: isAccepted
          ? `ডাঃ ${vetName} আপনার কনসালটেশন অ্যাপয়েন্টমেন্ট গ্রহণ করেছেন।`
          : `ডাঃ ${vetName} আপনার অ্যাপয়েন্টমেন্ট প্রস্তাব বাতিল করেছেন।`,
        data: {
          type: isAccepted ? 'RESERVATION_ACCEPTED' : 'RESERVATION_REJECTED',
          consultationId,
          vetName,
        },
        channelId: 'chat_messages',
      });
    }
  }

  // ── Vet: Accept ──────────────────────────────────────────────────────────

  async accept(id: string) {
    const c = await this._findOne(id);
    if (c.status !== 'PENDING') throw new BadRequestException('Only PENDING consultations can be accepted');
    const updated = await this.prisma.teleConsultation.update({
      where: { id },
      data: { status: 'CONFIRMED' },
      include: { farmer: { select: { id: true, name: true } }, vet: { select: { id: true, name: true } }, slot: true },
    });

    this._notifyFarmerStatusChange(id, updated.farmerId, updated.vet?.name || 'ডাক্তার', 'CONFIRMED').catch((e) => {
      this.logger.error('Failed to notify farmer of accepted reservation', e);
    });

    return updated;
  }

  // ── Vet: Reject ──────────────────────────────────────────────────────────

  async reject(id: string) {
    const c = await this._findOne(id);
    if (c.slotId) {
      await this.prisma.appointmentSlot.update({ where: { id: c.slotId }, data: { isBooked: false } });
    }
    const updated = await this.prisma.teleConsultation.update({
      where: { id },
      data: { status: 'REJECTED' },
      include: { farmer: { select: { id: true, name: true } }, vet: { select: { id: true, name: true } } },
    });

    this._notifyFarmerStatusChange(id, updated.farmerId, updated.vet?.name || 'ডাক্তার', 'REJECTED').catch((e) => {
      this.logger.error('Failed to notify farmer of rejected reservation', e);
    });

    return updated;
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
    await this.autoExpireStaleConsultations();

    let where: any;
    if (role === 'FARMER') {
      where = { farmerId: userId };
    } else {
      // Resolve all potential IDs (User ID and VetProfile ID)
      const profile = await this.prisma.vetProfile.findFirst({
        where: { OR: [{ id: userId }, { userId: userId }] },
      });
      const vetIds = profile ? Array.from(new Set([userId, profile.id, profile.userId])) : [userId];
      where = { vetId: { in: vetIds } };
    }

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

  async autoExpireStaleConsultations() {
    // Only expire if the consultation has passed by more than 24 hours
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const expired = await this.prisma.teleConsultation.findMany({
      where: {
        status: { in: ['PENDING', 'CONFIRMED'] },
        scheduledTime: { lt: oneDayAgo },
      },
      select: { id: true, slotId: true },
    });

    for (const c of expired) {
      if (c.slotId) {
        await this.prisma.appointmentSlot.update({ where: { id: c.slotId }, data: { isBooked: false } }).catch(() => {});
      }
      await this.prisma.teleConsultation.update({ where: { id: c.id }, data: { status: 'CANCELLED' } }).catch(() => {});
    }
  }

  async findAll(farmerId?: string, vetId?: string) {
    await this.autoExpireStaleConsultations();
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

  async cancel(id: string, cancelledByUserId?: string) {
    const c = await this._findOne(id);
    if (c.status === 'COMPLETED' || c.status === 'IN_PROGRESS') {
      throw new BadRequestException('Cannot cancel a consultation that is already in progress or completed');
    }
    if (c.status === 'CANCELLED') {
      throw new BadRequestException('Consultation is already cancelled');
    }

    if (c.slotId) {
      await this.prisma.appointmentSlot.update({ where: { id: c.slotId }, data: { isBooked: false } }).catch(() => {});
    }

    const updated = await this.prisma.teleConsultation.update({
      where: { id },
      data: { status: 'CANCELLED' },
      include: { farmer: { select: { id: true, name: true, fcmToken: true } }, vet: { select: { id: true, name: true, fcmToken: true } } },
    });

    // Notify opposite party
    const isFarmerCancelling = cancelledByUserId ? cancelledByUserId === c.farmerId : true;
    const recipientToken = isFarmerCancelling ? updated.vet?.fcmToken : updated.farmer?.fcmToken;
    const cancellerName = isFarmerCancelling ? updated.farmer?.name || 'কৃষক' : `ডাঃ ${updated.vet?.name || 'ডাক্তার'}`;

    if (recipientToken) {
      this.fcmService.sendGenericNotification({
        fcmToken: recipientToken,
        title: '❌ অ্যাপয়েন্টমেন্ট বাতিল করা হয়েছে',
        body: `${cancellerName} কনসালটেশন অ্যাপয়েন্টমেন্টটি বাতিল করেছেন।`,
        data: {
          type: 'RESERVATION_CANCELLED',
          consultationId: id,
        },
        channelId: 'chat_messages',
      }).catch((e) => this.logger.error('Failed to notify cancellation', e));
    }

    return updated;
  }

  async deletePermanent(id: string) {
    const c = await this.prisma.teleConsultation.findUnique({
      where: { id },
    });
    if (!c) {
      return { success: true, message: `Consultation ${id} already deleted` };
    }
    if (c.slotId) {
      await this.prisma.appointmentSlot.update({ where: { id: c.slotId }, data: { isBooked: false } }).catch(() => {});
    }
    await this.prisma.teleConsultation.delete({ where: { id } });
    return { success: true, message: `Consultation ${id} permanently deleted` };
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
