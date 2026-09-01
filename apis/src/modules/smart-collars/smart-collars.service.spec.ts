import { Test, TestingModule } from '@nestjs/testing';
import { SmartCollarsService } from './smart-collars.service';
import { PrismaService } from '../../database/prisma.service';

describe('SmartCollarsService', () => {
  let service: SmartCollarsService;
  const mockPrisma = {
    smartCollar: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SmartCollarsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<SmartCollarsService>(SmartCollarsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should trigger LED alert', async () => {
    mockPrisma.smartCollar.findUnique.mockResolvedValue({ id: 'c1', deviceCode: 'COLLAR-001' });
    const res = await service.triggerLedAlert('c1', 'RED');
    expect(res.success).toBe(true);
    expect(res.deviceId).toBe('COLLAR-001');
  });
});
