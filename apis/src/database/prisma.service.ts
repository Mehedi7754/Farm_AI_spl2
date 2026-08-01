import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() {
    await this.$connect();
    try {
      await this.$executeRawUnsafe('ALTER TABLE livestock ADD COLUMN IF NOT EXISTS name TEXT;');
    } catch (e) {
      console.error('Prisma auto-migration error:', e);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
