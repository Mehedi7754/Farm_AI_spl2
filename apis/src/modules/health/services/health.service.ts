import { Injectable } from '@nestjs/common';
import { HealthRequestDto } from '../dto/health-request.dto';
import { HealthResponseDto } from '../dto/health-response.dto';

@Injectable()
export class HealthService {
  getHealth(payload?: HealthRequestDto): HealthResponseDto {
    return {
      service: 'apis',
      status: 'ok',
      timestamp: new Date().toISOString(),
      source: payload?.source,
    };
  }
}
