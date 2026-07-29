import { Body, Controller, Get, Post, UploadedFile, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBody, ApiConsumes, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
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

  @Post('diagnose')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Run PaliGemma 3B AI Cow Disease Diagnosis' })
  diagnose(
    @Body() body: any,
    @UploadedFile() file?: any,
  ) {
    const livestockId = body?.livestockId || '8961e29c-2495-49b8-9a77-7b619f1c937a';
    let imageBuffer = file?.buffer;
    if (!imageBuffer && file?.path) {
      const fs = require('fs');
      imageBuffer = fs.readFileSync(file.path);
    }

    return this.healthService.diagnoseCowDisease(
      livestockId,
      imageBuffer,
      file?.originalname,
    );
  }
}
