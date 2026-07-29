import { Test, TestingModule } from '@nestjs/testing';
import { VaccinationsService } from './vaccinations.service';
import { PrismaService } from '../../database/prisma.service';

describe('VaccinationsService', () => {
  let service: VaccinationsService;
  const mockPrisma = {
    vaccination: {
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
        VaccinationsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<VaccinationsService>(VaccinationsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create vaccination record', async () => {
    const dto = { livestockId: 'l1', vaccineName: 'FMD Vaccine', scheduledDate: '2026-08-01' };
    mockPrisma.vaccination.create.mockResolvedValue({ id: 'v1', ...dto, isDone: false });

    const res = await service.create(dto as any);
    expect(res.id).toBe('v1');
  });
});
