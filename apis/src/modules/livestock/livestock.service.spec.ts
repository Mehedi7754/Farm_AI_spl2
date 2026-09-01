import { Test, TestingModule } from '@nestjs/testing';
import { LivestockService } from './livestock.service';
import { PrismaService } from '../../database/prisma.service';

describe('LivestockService', () => {
  let service: LivestockService;
  const mockPrisma = {
    livestock: {
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
        LivestockService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<LivestockService>(LivestockService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create livestock', async () => {
    const dto = { farmerId: 'f1', species: 'Cow', breed: 'Friesian', dateOfBirth: '2024-01-01', gender: 'FEMALE', weight: 350 };
    mockPrisma.livestock.create.mockResolvedValue({ id: 'l1', ...dto });

    const result = await service.create(dto as any);
    expect(result.id).toBe('l1');
  });
});
