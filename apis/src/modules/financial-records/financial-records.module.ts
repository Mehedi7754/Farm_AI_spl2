import { Module } from '@nestjs/common';
import { FinancialRecordsController } from './financial-records.controller';
import { FinancialRecordsService } from './financial-records.service';

@Module({
  controllers: [FinancialRecordsController],
  providers: [FinancialRecordsService],
  exports: [FinancialRecordsService],
})
export class FinancialRecordsModule {}
