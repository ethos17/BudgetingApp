import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { PlaidConfig } from './plaid.config';
import { PlaidController } from './plaid.controller';
import { PlaidService } from './plaid.service';

@Module({
  imports: [ConfigModule, PrismaModule],
  controllers: [PlaidController],
  providers: [PlaidConfig, PlaidService],
  exports: [PlaidService],
})
export class PlaidModule {}
