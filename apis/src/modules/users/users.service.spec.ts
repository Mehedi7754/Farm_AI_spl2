import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../../database/prisma.service';

describe('UsersService', () => {
  let service: UsersService;
  let prisma: PrismaService;

  const mockPrisma = {
    user: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create a user', async () => {
    const dto = { name: 'Rahim Farmer', email: 'rahim@farm.ai', phoneNumber: '+8801700000000' };
    mockPrisma.user.create.mockResolvedValue({ id: 'u1', ...dto, role: 'FARMER' });

    const result = await service.create(dto as any);
    expect(result.id).toBe('u1');
    expect(mockPrisma.user.create).toHaveBeenCalledWith({ data: dto });
  });

  it('should return all users', async () => {
    mockPrisma.user.findMany.mockResolvedValue([{ id: 'u1', name: 'Rahim' }]);
    const result = await service.findAll();
    expect(result).toHaveLength(1);
  });
});
