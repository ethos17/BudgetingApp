import { Module } from '@nestjs/common';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';
import { FINANCIAL_DATA_PROVIDER } from '../providers/financial-data.provider';
import { MockFinancialDataProvider } from '../providers/mock-financial-data.provider';

@Module({
  controllers: [SyncController],
  providers: [
    SyncService,
    {
      provide: FINANCIAL_DATA_PROVIDER,
      useClass: MockFinancialDataProvider,
    },
  ],
})
export class SyncModule {}
