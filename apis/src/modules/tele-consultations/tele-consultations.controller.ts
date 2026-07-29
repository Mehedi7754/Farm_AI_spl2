import { Controller, Get, Post, Body, Patch, Param, Query, Delete } from '@nestjs/common';
import { TeleConsultationsService } from './tele-consultations.service';
import { CreateTeleConsultationDto } from './dto/create-tele-consultation.dto';
import { UpdateTeleConsultationDto } from './dto/update-tele-consultation.dto';

@Controller('tele-consultations')
export class TeleConsultationsController {
  constructor(private readonly teleConsultationsService: TeleConsultationsService) {}

  @Post()
  create(@Body() dto: CreateTeleConsultationDto) {
    return this.teleConsultationsService.create(dto);
  }

  @Get()
  findAll(@Query('farmerId') farmerId?: string, @Query('vetId') vetId?: string) {
    return this.teleConsultationsService.findAll(farmerId, vetId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.teleConsultationsService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTeleConsultationDto) {
    return this.teleConsultationsService.update(id, dto);
  }

  @Delete(':id')
  cancel(@Param('id') id: string) {
    return this.teleConsultationsService.cancel(id);
  }
}
