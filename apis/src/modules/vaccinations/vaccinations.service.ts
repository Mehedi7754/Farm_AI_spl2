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

  async getAiRecommendations(diseaseQuery?: string) {
    const recommendations = [
      {
        disease: 'খুরা রোগ (FMD - Foot & Mouth Disease)',
        diseaseKey: 'FMD',
        vaccineName: 'FMD ৩-ভ্যালেন্ট ভ্যাক্সিন ( trivalent FMD Vaccine )',
        type: 'টিকা',
        boosterDays: 180, // 6 months
        recommendedAge: '৪ মাস বয়স থেকে',
        notes: 'প্রতি ৬ মাস পর পর বুস্টার ডোজ দিতে হবে। বর্ষাকালের আগে দেওয়া উত্তম।',
      },
      {
        disease: 'তড়কা রোগ (Anthrax)',
        diseaseKey: 'ANTHRAX',
        vaccineName: 'তড়কা (Anthrax) ভ্যাক্সিন',
        type: 'টিকা',
        boosterDays: 365, // 1 year
        recommendedAge: '৬ মাস বয়স থেকে',
        notes: 'বছরে ১ বার দেওয়া আবশ্যক। মহামারীপ্রবণ এলাকায় জরুরি টিকা।',
      },
      {
        disease: 'গলাফুলা (HS - Haemorrhagic Septicaemia)',
        diseaseKey: 'HS',
        vaccineName: 'গলাফুলা (HS) ভ্যাক্সিন',
        type: 'টিকা',
        boosterDays: 180, // 6 months
        recommendedAge: '৬ মাস বয়স থেকে',
        notes: 'বর্ষার শুরুতে এবং প্রতি ৬ মাস পর বুস্টার ডোজ দিতে হয়।',
      },
      {
        disease: 'বাদলা রোগ (BQ - Blackquarter)',
        diseaseKey: 'BQ',
        vaccineName: 'বাদলা (BQ) ভ্যাক্সিন',
        type: 'টিকা',
        boosterDays: 180, // 6 months
        recommendedAge: '৬ মাস থেকে ২ বছর বয়সী বাছুর',
        notes: 'প্রতি ৬ মাস পর বুস্টার দিতে হবে। কচি ঘাস খাওয়ার মৌসুমে দরকার।',
      },
      {
        disease: 'ল্যাম্পি স্কিন ডিজিজ (LSD - Lumpy Skin Disease)',
        diseaseKey: 'LSD',
        vaccineName: 'ল্যাম্পি স্কিন (LSD / GoatPox) ভ্যাক্সিন',
        type: 'টিকা',
        boosterDays: 365, // 1 year
        recommendedAge: '৩ মাস বয়স থেকে',
        notes: 'মশাবাহিত রোগের প্রতিরোধে বছরে ১ বার টিকা দিন।',
      },
      {
        disease: 'কৃমি ও পরজীবী সংক্রমণ (Helminthiasis / Deworming)',
        diseaseKey: 'DEWORMER',
        vaccineName: 'অ্যালবেনডাজল / লেভামিসল (Dewormer Bolus)',
        type: 'কৃমিনাশক',
        boosterDays: 90, // 3 months
        recommendedAge: 'সকল বয়সের গবাদিপশু',
        notes: 'প্রতি ৩ মাস পর পর কৃমিনাশক প্রদান ও পেটের পরাশ্রয়ী দূর করা আবশ্যক।',
      },
      {
        disease: 'ভিটামিন ও খনিজ ঘাটতি (Deficiency / Tonic)',
        diseaseKey: 'VITAMIN',
        vaccineName: 'ভিটামিন AD3E / ক্যালসিয়াম ইনজেকশন',
        type: 'ভিটামিন',
        boosterDays: 30, // 1 month
        recommendedAge: 'দুগ্ধবতী গাভী ও দুর্বল পশুকে',
        notes: 'দুধের উৎপাদন বৃদ্ধি ও শারীরিক শক্তি বাড়াতে প্রতি মাসে কোর্স করান।',
      },
      {
        disease: 'রেবিস / জলাতঙ্ক (Rabies)',
        diseaseKey: 'RABIES',
        vaccineName: 'রেবিস (Rabies) প্রতিরোধক ভ্যাক্সিন',
        type: 'টিকা',
        boosterDays: 365, // 1 year
        recommendedAge: '৩ মাস বয়স থেকে',
        notes: 'পাগল কুকুর বা কামড়ের ঝুঁকিতে বছরে ১ বার দিন।',
      },
    ];

    if (diseaseQuery) {
      const q = diseaseQuery.toLowerCase();
      return recommendations.filter(
        (r) =>
          r.disease.toLowerCase().includes(q) ||
          r.vaccineName.toLowerCase().includes(q) ||
          r.diseaseKey.toLowerCase().includes(q),
      );
    }

    return recommendations;
  }

  async remove(id: string) {
    await this.findOne(id);
    return this.prisma.vaccination.delete({
      where: { id },
    });
  }
}
