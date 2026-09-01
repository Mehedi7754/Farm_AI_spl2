import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateVetProfileDto } from './dto/create-vet-profile.dto';

@Injectable()
export class VetProfilesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateVetProfileDto) {
    const existing = await this.prisma.vetProfile.findUnique({ where: { userId: dto.userId } });
    if (existing) throw new ConflictException('Vet profile already exists for this user');

    return this.prisma.vetProfile.create({
      data: {
        userId: dto.userId,
        licenseNumber: dto.licenseNumber,
        specialization: dto.specialization,
        experienceYears: dto.experienceYears ?? 0,
        consultationFee: dto.consultationFee ?? 0,
        availableFrom: dto.availableFrom ?? '09:00',
        availableTo: dto.availableTo ?? '18:00',
        availableDays: dto.availableDays ?? ['SAT', 'SUN', 'MON', 'TUE', 'WED'],
        bio: dto.bio,
        profileImageUrl: dto.profileImageUrl,
        latitude: dto.latitude,
        longitude: dto.longitude,
        district: dto.district,
      },
      include: { user: { select: { id: true, name: true, email: true, phoneNumber: true, location: true } } },
    });
  }

  async findAll(filters?: { specialization?: string; district?: string; isAvailable?: boolean }) {
    const where: any = {};
    if (filters?.specialization) where.specialization = filters.specialization;
    if (filters?.district) where.district = { contains: filters.district, mode: 'insensitive' };
    if (filters?.isAvailable !== undefined) where.isAvailable = filters.isAvailable;

    return this.prisma.vetProfile.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, email: true, phoneNumber: true, location: true, role: true } },
      },
      orderBy: [{ rating: 'desc' }, { totalReviews: 'desc' }],
    });
  }

  async findByUserId(userId: string) {
    const profile = await this.prisma.vetProfile.findUnique({
      where: { userId },
      include: {
        user: { select: { id: true, name: true, email: true, phoneNumber: true, location: true } },
      },
    });
    if (!profile) throw new NotFoundException('Vet profile not found');
    return profile;
  }

  async update(userId: string, dto: Partial<CreateVetProfileDto>) {
    await this.findByUserId(userId);

    return this.prisma.vetProfile.update({
      where: { userId },
      data: dto,
      include: { user: { select: { id: true, name: true, email: true, phoneNumber: true, location: true } } },
    });
  }

  async setAvailability(userId: string, isAvailable: boolean) {
    return this.prisma.vetProfile.update({ where: { userId }, data: { isAvailable } });
  }

  // ── Slots ──────────────────────────────────────────────────────────────────

  async createSlots(vetId: string, slots: { date: string; startTime: string; endTime: string }[]) {
    let realUserId = vetId;
    const profile = await this.prisma.vetProfile.findFirst({
      where: { OR: [{ id: vetId }, { userId: vetId }] },
    });
    if (profile) {
      realUserId = profile.userId;
    }

    const data = slots.map((s) => ({
      vetId: realUserId,
      date: new Date(s.date),
      startTime: s.startTime,
      endTime: s.endTime,
    }));
    return this.prisma.appointmentSlot.createMany({ data, skipDuplicates: true });
  }

  async getSlots(vetId: string, date?: string) {
    let realUserId = vetId;
    const profile = await this.prisma.vetProfile.findFirst({
      where: { OR: [{ id: vetId }, { userId: vetId }] },
    });
    if (profile) {
      realUserId = profile.userId;
    }

    const where: any = {
      OR: [{ vetId: realUserId }, { vetId }],
    };

    if (date) {
      const d = new Date(date);
      const start = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, 0, 0));
      const end = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + 1, 23, 59, 59));
      where.date = { gte: start, lte: end };
    }

    return this.prisma.appointmentSlot.findMany({ where, orderBy: [{ date: 'asc' }, { startTime: 'asc' }] });
  }

  async updateSlot(slotId: string, data: { startTime?: string; endTime?: string; date?: string }) {
    const updateData: any = {};
    if (data.startTime) updateData.startTime = data.startTime;
    if (data.endTime) updateData.endTime = data.endTime;
    if (data.date) updateData.date = new Date(data.date);

    return this.prisma.appointmentSlot.update({
      where: { id: slotId },
      data: updateData,
    });
  }

  async deleteSlot(slotId: string) {
    return this.prisma.appointmentSlot.delete({
      where: { id: slotId },
    });
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  async addReview(vetId: string, farmerId: string, rating: number, comment?: string) {
    const review = await this.prisma.vetReview.upsert({
      where: { vetId_farmerId: { vetId, farmerId } },
      update: { rating, comment },
      create: { vetId, farmerId, rating, comment },
    });

    const reviews = await this.prisma.vetReview.findMany({ where: { vetId } });
    const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

    await this.prisma.vetProfile.update({
      where: { userId: vetId },
      data: { rating: avgRating, totalReviews: reviews.length },
    });

    return review;
  }
}
