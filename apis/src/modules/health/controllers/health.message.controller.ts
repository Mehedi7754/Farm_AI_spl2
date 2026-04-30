import { Controller } from '@nestjs/common';
import { MessagePattern, Payload } from '@nestjs/microservices';
import { HealthRequestDto } from '../dto/health-request.dto';
import { HealthResponseDto } from '../dto/health-response.dto';
import { HealthService } from '../services/health.service';

@Controller()
export class HealthMessageController {
  constructor(private readonly healthService: HealthService) {}

  @MessagePattern('health')
  getHealth(@Payload() payload?: HealthRequestDto): HealthResponseDto {
    return this.healthService.getHealth(payload);
  }
}
