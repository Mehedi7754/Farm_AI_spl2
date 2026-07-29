import { Injectable, NotFoundException, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreateUserDto, LoginUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as jwt from 'jsonwebtoken';
import * as bcrypt from 'bcryptjs';

const JWT_SECRET = process.env.JWT_SECRET || 'farm_ai_jwt_secret_key_2026_super_secure';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async register(dto: CreateUserDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existing) {
      throw new BadRequestException('ইমেইলটি ইতোমধ্যে নিবন্ধিত রয়েছে। (Email already registered)');
    }

    if (!dto.password || dto.password.length < 6) {
      throw new BadRequestException('পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে।');
    }

    const hashedPassword = await bcrypt.hash(dto.password, 10);
    const phone = dto.phoneNumber || `017${Math.floor(10000000 + Math.random() * 90000000)}`;

    const user = await this.prisma.user.create({
      data: {
        name: dto.name,
        email: dto.email,
        password: hashedPassword,
        phoneNumber: phone,
        role: dto.role || 'FARMER',
        location: dto.location || 'বাংলাদেশ',
      },
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return {
      message: 'সফলভাবে নিবন্ধন সম্পন্ন হয়েছে!',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        location: user.location,
      },
    };
  }

  async login(dto: LoginUserDto) {
    if (!dto.email || !dto.password) {
      throw new BadRequestException('ইমেইল এবং পাসওয়ার্ড আবশ্যক।');
    }

    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user) {
      throw new UnauthorizedException('ভুল ইমেইল অথবা পাসওয়ার্ড প্রদান করা হয়েছে।');
    }

    const isMatch = await bcrypt.compare(dto.password, user.password).catch(() => false);
    if (!isMatch && user.password !== dto.password) {
      throw new UnauthorizedException('ভুল ইমেইল অথবা পাসওয়ার্ড প্রদান করা হয়েছে।');
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    return {
      message: 'সফলভাবে লগইন হয়েছে!',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        location: user.location,
      },
    };
  }

  async findAll() {
    return this.prisma.user.findMany();
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    await this.findOne(id);

    return this.prisma.user.update({
      where: { id },
      data: updateUserDto,
    });
  }

  async remove(id: string) {
    await this.findOne(id);

    return this.prisma.user.delete({
      where: { id },
    });
  }

  async getDistricts() {
    let dbDistricts = await this.prisma.district.findMany({
      orderBy: { name: 'asc' },
    });

    if (!dbDistricts || dbDistricts.length === 0) {
      const seedList = [
        { name: 'Dhaka', nameBn: 'ঢাকা', division: 'Dhaka' },
        { name: 'Gazipur', nameBn: 'গাজীপুর', division: 'Dhaka' },
        { name: 'Narayanganj', nameBn: 'নারায়ণগঞ্জ', division: 'Dhaka' },
        { name: 'Tangail', nameBn: 'টাঙ্গাইল', division: 'Dhaka' },
        { name: 'Faridpur', nameBn: 'ফরিদপুর', division: 'Dhaka' },
        { name: 'Manikganj', nameBn: 'মানিকগঞ্জ', division: 'Dhaka' },
        { name: 'Munshiganj', nameBn: 'মুন্সীগঞ্জ', division: 'Dhaka' },
        { name: 'Narsingdi', nameBn: 'নরসিংদী', division: 'Dhaka' },
        { name: 'Rajbari', nameBn: 'রাজবাড়ী', division: 'Dhaka' },
        { name: 'Gopalganj', nameBn: 'গোপালগঞ্জ', division: 'Dhaka' },
        { name: 'Madaripur', nameBn: 'মাদারীপুর', division: 'Dhaka' },
        { name: 'Shariatpur', nameBn: 'শরীয়তপুর', division: 'Dhaka' },
        { name: 'Kishoreganj', nameBn: 'কিশোরগঞ্জ', division: 'Dhaka' },
        { name: 'Chattogram', nameBn: 'চট্টগ্রাম', division: 'Chattogram' },
        { name: 'Cox\'s Bazar', nameBn: 'কক্সবাজার', division: 'Chattogram' },
        { name: 'Cumilla', nameBn: 'কুমিল্লা', division: 'Chattogram' },
        { name: 'Feni', nameBn: 'ফেনী', division: 'Chattogram' },
        { name: 'Brahmanbaria', nameBn: 'ব্রাহ্মণবাড়িয়া', division: 'Chattogram' },
        { name: 'Noakhali', nameBn: 'নোয়াখালী', division: 'Chattogram' },
        { name: 'Chandpur', nameBn: 'চাঁদপুর', division: 'Chattogram' },
        { name: 'Lakshmipur', nameBn: 'লক্ষ্মীপুর', division: 'Chattogram' },
        { name: 'Rangamati', nameBn: 'রাঙ্গামাটি', division: 'Chattogram' },
        { name: 'Bandarban', nameBn: 'বান্দরবান', division: 'Chattogram' },
        { name: 'Khagrachhari', nameBn: 'খাগড়াছড়ি', division: 'Chattogram' },
        { name: 'Rajshahi', nameBn: 'রাজশাহী', division: 'Rajshahi' },
        { name: 'Bogra', nameBn: 'বগুড়া', division: 'Rajshahi' },
        { name: 'Pabna', nameBn: 'পাবনা', division: 'Rajshahi' },
        { name: 'Sirajganj', nameBn: 'সিরাজগঞ্জ', division: 'Rajshahi' },
        { name: 'Naogaon', nameBn: 'নওগাঁ', division: 'Rajshahi' },
        { name: 'Natore', nameBn: 'নাটোর', division: 'Rajshahi' },
        { name: 'Chapainawabganj', nameBn: 'চাঁপাইনবাবগঞ্জ', division: 'Rajshahi' },
        { name: 'Joypurhat', nameBn: 'জয়পুরহাট', division: 'Rajshahi' },
        { name: 'Khulna', nameBn: 'খুলনা', division: 'Khulna' },
        { name: 'Jashore', nameBn: 'যশোর', division: 'Khulna' },
        { name: 'Kushtia', nameBn: 'কুষ্টিয়া', division: 'Khulna' },
        { name: 'Satkhira', nameBn: 'সাতক্ষীরা', division: 'Khulna' },
        { name: 'Jhenaidah', nameBn: 'ঝিনাইদহ', division: 'Khulna' },
        { name: 'Bagerhat', nameBn: 'বাগেরহাট', division: 'Khulna' },
        { name: 'Chuadanga', nameBn: 'চুয়াডাঙ্গা', division: 'Khulna' },
        { name: 'Meherpur', nameBn: 'মেহেরপুর', division: 'Khulna' },
        { name: 'Narail', nameBn: 'নড়াইল', division: 'Khulna' },
        { name: 'Magura', nameBn: 'মাগুরা', division: 'Khulna' },
        { name: 'Barishal', nameBn: 'বরিশাল', division: 'Barishal' },
        { name: 'Patuakhali', nameBn: 'পটুয়াখালী', division: 'Barishal' },
        { name: 'Bhola', nameBn: 'ভোলা', division: 'Barishal' },
        { name: 'Pirojpur', nameBn: 'পিরোজপুর', division: 'Barishal' },
        { name: 'Barguna', nameBn: 'বরগুনা', division: 'Barishal' },
        { name: 'Jhalokati', nameBn: 'ঝালকাঠি', division: 'Barishal' },
        { name: 'Sylhet', nameBn: 'সিলেট', division: 'Sylhet' },
        { name: 'Moulvibazar', nameBn: 'মৌলভীবাজার', division: 'Sylhet' },
        { name: 'Habiganj', nameBn: 'হবিগঞ্জ', division: 'Sylhet' },
        { name: 'Sunamganj', nameBn: 'সুনামগঞ্জ', division: 'Sylhet' },
        { name: 'Rangpur', nameBn: 'রংপুর', division: 'Rangpur' },
        { name: 'Dinajpur', nameBn: 'দিনাজপুর', division: 'Rangpur' },
        { name: 'Gaibandha', nameBn: 'গাইবান্ধা', division: 'Rangpur' },
        { name: 'Kurigram', nameBn: 'কুড়িগ্রাম', division: 'Rangpur' },
        { name: 'Lalmonirhat', nameBn: 'লালমনিরহাট', division: 'Rangpur' },
        { name: 'Nilphamari', nameBn: 'নীলফামারী', division: 'Rangpur' },
        { name: 'Panchagarh', nameBn: 'পঞ্চগড়', division: 'Rangpur' },
        { name: 'Thakurgaon', nameBn: 'ঠাকুরগাঁও', division: 'Rangpur' },
        { name: 'Mymensingh', nameBn: 'ময়মনসিংহ', division: 'Mymensingh' },
        { name: 'Jamalpur', nameBn: 'জামালপুর', division: 'Mymensingh' },
        { name: 'Sherpur', nameBn: 'শেরপুর', division: 'Mymensingh' },
        { name: 'Netrokona', nameBn: 'নেত্রকোনা', division: 'Mymensingh' },
      ];

      try {
        for (const item of seedList) {
          await this.prisma.district.upsert({
            where: { name: item.name },
            update: { nameBn: item.nameBn, division: item.division },
            create: { name: item.name, nameBn: item.nameBn, division: item.division },
          });
        }
        dbDistricts = await this.prisma.district.findMany({
          orderBy: { name: 'asc' },
        });
      } catch (_) {}
    }

    if (dbDistricts && dbDistricts.length > 0) {
      return dbDistricts.map((d) => `${d.nameBn} (${d.name})`);
    }

    return [
      'ঢাকা (Dhaka)',
      'গাজীপুর (Gazipur)',
      'নারায়ণগঞ্জ (Narayanganj)',
      'টাঙ্গাইল (Tangail)',
      'ফরিদপুর (Faridpur)',
      'মানিকগঞ্জ (Manikganj)',
      'মুন্সীগঞ্জ (Munshiganj)',
      'নরসিংদী (Narsingdi)',
      'রাজবাড়ী (Rajbari)',
      'গোপালগঞ্জ (Gopalganj)',
      'মাদারীপুর (Madaripur)',
      'শরীয়তপুর (Shariatpur)',
      'কিশোরগঞ্জ (Kishoreganj)',
      'চট্টগ্রাম (Chattogram)',
      'কক্সবাজার (Cox\'s Bazar)',
      'কুমিল্লা (Cumilla)',
      'ফেনী (Feni)',
      'ব্রাহ্মণবাড়িয়া (Brahmanbaria)',
      'নোয়াখালী (Noakhali)',
      'চাঁদপুর (Chandpur)',
      'লক্ষ্মীপুর (Lakshmipur)',
      'রাঙ্গামাটি (Rangamati)',
      'বান্দরবান (Bandarban)',
      'খাগড়াছড়ি (Khagrachhari)',
      'রাজশাহী (Rajshahi)',
      'বগুড়া (Bogra)',
      'পাবনা (Pabna)',
      'সিরাজগঞ্জ (Sirajganj)',
      'নওগাঁ (Naogaon)',
      'নাটোর (Natore)',
      'চাঁপাইনবাবগঞ্জ (Chapainawabganj)',
      'জয়পুরহাট (Joypurhat)',
      'খুলনা (Khulna)',
      'যশোর (Jashore)',
      'কুষ্টিয়া (Kushtia)',
      'সাতক্ষীরা (Satkhira)',
      'ঝিনাইদহ (Jhenaidah)',
      'বাগেরহাট (Bagerhat)',
      'চুয়াডাঙ্গা (Chuadanga)',
      'মেহেরপুর (Meherpur)',
      'নড়াইল (Narail)',
      'মাগুরা (Magura)',
      'বরিশাল (Barishal)',
      'পটুয়াখালী (Patuakhali)',
      'ভোলা (Bhola)',
      'পিরোজপুর (Pirojpur)',
      'বরগুনা (Barguna)',
      'ঝালকাঠি (Jhalokati)',
      'সিলেট (Sylhet)',
      'মৌলভীবাজার (Moulvibazar)',
      'হবিগঞ্জ (Habiganj)',
      'সুনামগঞ্জ (Sunamganj)',
      'রংপুর (Rangpur)',
      'দিনাজপুর (Dinajpur)',
      'গাইবান্ধা (Gaibandha)',
      'কুড়িগ্রাম (Kurigram)',
      'লালমনিরহাট (Lalmonirhat)',
      'নীলফামারী (Nilphamari)',
      'পঞ্চগড় (Panchagarh)',
      'ঠাকুরগাঁও (Thakurgaon)',
      'ময়মনসিংহ (Mymensingh)',
      'জামালপুর (Jamalpur)',
      'শেরপুর (Sherpur)',
      'নেত্রকোনা (Netrokona)',
    ];
  }
}
