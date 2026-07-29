import { Test, TestingModule } from '@nestjs/testing';
import { CommunityService } from './community.service';
import { PrismaService } from '../../database/prisma.service';

describe('CommunityService', () => {
  let service: CommunityService;
  const mockPrisma = {
    communityPost: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      delete: jest.fn(),
    },
    communityComment: {
      create: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommunityService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<CommunityService>(CommunityService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create post', async () => {
    const dto = { authorId: 'a1', title: 'Feed tips', content: 'Use green grass' };
    mockPrisma.communityPost.create.mockResolvedValue({ id: 'p1', ...dto });

    const res = await service.createPost(dto as any);
    expect(res.id).toBe('p1');
  });
});
