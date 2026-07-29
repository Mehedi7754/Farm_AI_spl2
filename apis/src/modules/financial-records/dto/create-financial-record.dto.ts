import { IsString, IsNotEmpty, IsEnum, IsNumber, IsOptional } from 'class-validator';
import { TransactionType } from '@prisma/client';

export class CreateFinancialRecordDto {
  @IsString()
  @IsNotEmpty()
  farmerId: string;

  @IsEnum(TransactionType)
  @IsNotEmpty()
  type: TransactionType; // INCOME or EXPENSE

  @IsNumber()
  @IsNotEmpty()
  amount: number;

  @IsString()
  @IsNotEmpty()
  category: string; // e.g. "Milk Sales", "Feed Purchase", "Medicine", "Vaccine"

  @IsString()
  @IsOptional()
  description?: string;
}
