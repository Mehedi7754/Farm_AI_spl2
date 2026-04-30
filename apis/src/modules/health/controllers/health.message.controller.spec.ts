import { Test, TestingModule } from '@nestjs/testing';
import { HealthMessageController } from './health.message.controller';
import { HealthService } from '../services/health.service';

describe('HealthMessageController', () => {
  let controller: HealthMessageController;
  let service: HealthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthMessageController],
      providers: [HealthService],
    }).compile();

    controller = module.get<HealthMessageController>(HealthMessageController);
    service = module.get<HealthService>(HealthService);
  });

  it('delegates health message handling to service', () => {
    const serviceSpy = jest.spyOn(service, 'getHealth');
    const payload = { source: 'flutter-app' };

    const response = controller.getHealth(payload);

    expect(serviceSpy).toHaveBeenCalledWith(payload);
    expect(response.status).toBe('ok');
  });
});
