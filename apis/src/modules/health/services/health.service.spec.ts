import { HealthService } from './health.service';

describe('HealthService', () => {
  let service: HealthService;

  beforeEach(() => {
    service = new HealthService();
  });

  it('returns default health payload', () => {
    const result = service.getHealth();

    expect(result.service).toBe('apis');
    expect(result.status).toBe('ok');
    expect(result.source).toBeUndefined();
    expect(new Date(result.timestamp).toString()).not.toBe('Invalid Date');
  });

  it('keeps source from payload', () => {
    const result = service.getHealth({ source: 'flutter-app' });

    expect(result.source).toBe('flutter-app');
  });
});
