import { Controller, Get, Post, Body, Param, Query, Delete } from '@nestjs/common';
import { FinancialRecordsService } from './financial-records.service';
import { CreateFinancialRecordDto } from './dto/create-financial-record.dto';

@Controller('financial-records')
export class FinancialRecordsController {
  constructor(private readonly financialRecordsService: FinancialRecordsService) {}

  @Post()
  create(@Body() dto: CreateFinancialRecordDto) {
    return this.financialRecordsService.create(dto);
  }

  @Get()
  findAll(@Query('farmerId') farmerId?: string) {
    return this.financialRecordsService.findAll(farmerId);
  }

  @Get('summary/:farmerId')
  getSummary(@Param('farmerId') farmerId: string) {
    return this.financialRecordsService.getSummary(farmerId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.financialRecordsService.findOne(id);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.financialRecordsService.remove(id);
  }
}
