import { Test, TestingModule } from '@nestjs/testing';
import { FinancialRecordsService } from './financial-records.service';
import { PrismaService } from '../../database/prisma.service';

describe('FinancialRecordsService', () => {
  let service: FinancialRecordsService;
  const mockPrisma = {
    financialRecord: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FinancialRecordsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<FinancialRecordsService>(FinancialRecordsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should compute net profit in summary', async () => {
    mockPrisma.financialRecord.findMany.mockResolvedValue([
      { type: 'INCOME', amount: 5000 },
      { type: 'EXPENSE', amount: 1500 },
    ]);

    const res = await service.getSummary('farmer-1');
    expect(res.totalIncome).toBe(5000);
    expect(res.totalExpense).toBe(1500);
    expect(res.netProfit).toBe(3500);
  });
});
