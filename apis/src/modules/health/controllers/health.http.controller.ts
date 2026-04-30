import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBody, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { HealthRequestDto } from '../dto/health-request.dto';
import { HealthResponseDto } from '../dto/health-response.dto';
import { HealthService } from '../services/health.service';

@ApiTags('health')
@Controller('health')
export class HealthHttpController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  @ApiOperation({ summary: 'Get health status' })
  @ApiResponse({ status: 200, type: HealthResponseDto })
  getHealth(): HealthResponseDto {
    return this.healthService.getHealth();
  }

  @Post()
  @ApiOperation({ summary: 'Get health status with request payload' })
  @ApiBody({ type: HealthRequestDto })
  @ApiResponse({ status: 201, type: HealthResponseDto })
  postHealth(@Body() payload: HealthRequestDto): HealthResponseDto {
    return this.healthService.getHealth(payload);
  }
}
