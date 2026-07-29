import { Test, TestingModule } from '@nestjs/testing';
import { MapsService } from './maps.service';

describe('MapsService', () => {
  let service: MapsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [MapsService],
    }).compile();

    service = module.get<MapsService>(MapsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should find nearby vet hospitals for coordinates', async () => {
    const res = await service.findNearbyVets({ lat: 23.8103, lng: 90.4125, radius: 5000 });
    expect(res).toBeDefined();
    expect(res.vets.length).toBeGreaterThan(0);
    expect(res.vets[0].name).toBeTruthy();
  });
});
