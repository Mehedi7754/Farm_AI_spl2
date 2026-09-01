import { Controller, Get, Post, Body, Patch, Param, Delete, Query } from '@nestjs/common';
import { LivestockService } from './livestock.service';
import { CreateLivestockDto } from './dto/create-livestock.dto';
import { UpdateLivestockDto } from './dto/update-livestock.dto';

@Controller('livestock')
export class LivestockController {
  constructor(private readonly livestockService: LivestockService) {}

  @Post()
  create(@Body() createLivestockDto: CreateLivestockDto) {
    return this.livestockService.create(createLivestockDto);
  }

  @Get()
  findAll(@Query('farmerId') farmerId?: string) {
    return this.livestockService.findAll(farmerId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.livestockService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateLivestockDto: UpdateLivestockDto) {
    return this.livestockService.update(id, updateLivestockDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.livestockService.remove(id);
  }
}
