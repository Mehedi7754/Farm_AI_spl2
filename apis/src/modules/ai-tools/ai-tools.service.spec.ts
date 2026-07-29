import { Test, TestingModule } from '@nestjs/testing';
import { AiToolsService } from './ai-tools.service';

describe('AiToolsService', () => {
  let service: AiToolsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AiToolsService],
    }).compile();

    service = module.get<AiToolsService>(AiToolsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should handle voice chat request', async () => {
    const res = await service.voiceChat({ message: 'গরুর পাতলা পায়খানা হলে কি করণীয়?', language: 'bn' });
    expect(res).toBeDefined();
    expect(res.reply).toBeTruthy();
  });

  it('should analyze symptoms and return risk level', async () => {
    const res = await service.analyzeSymptoms({ symptoms: ['lumpy skin lesions', 'swelling'], species: 'Cow' });
    expect(res.riskLevel).toBe('EMERGENCY');
    expect(res.analysis).toBeTruthy();
  });

  it('should transcribe audio input', async () => {
    const res = await service.transcribeAudio(Buffer.from('test audio'), 'test.mp3');
    expect(res.text).toBeTruthy();
  });
});
