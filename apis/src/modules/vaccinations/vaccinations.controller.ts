import { Controller, Get, Post, Body, Patch, Param, Query, Delete } from '@nestjs/common';
import { VaccinationsService } from './vaccinations.service';
import { CreateVaccinationDto } from './dto/create-vaccination.dto';
import { UpdateVaccinationDto } from './dto/update-vaccination.dto';

@Controller('vaccinations')
export class VaccinationsController {
  constructor(private readonly vaccinationsService: VaccinationsService) {}

  @Post()
  create(@Body() dto: CreateVaccinationDto) {
    return this.vaccinationsService.create(dto);
  }

  @Get()
  findAll(@Query('livestockId') livestockId?: string) {
    return this.vaccinationsService.findAll(livestockId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.vaccinationsService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateVaccinationDto) {
    return this.vaccinationsService.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.vaccinationsService.remove(id);
  }
}
