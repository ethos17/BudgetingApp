import * as path from 'path';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { PrismaModule } from './prisma/prisma.module';
import { CategoriesModule } from './categories/categories.module';
import { SettingsModule } from './settings/settings.module';
import { AccountsModule } from './accounts/accounts.module';
import { TransactionsModule } from './transactions/transactions.module';
import { BudgetsModule } from './budgets/budgets.module';
import { RulesModule } from './rules/rules.module';
import { NotificationsModule } from './notifications/notifications.module';
import { SyncModule } from './sync/sync.module';
import { PlaidModule } from './plaid/plaid.module';

// Resolve .env from api app dir (works when run from repo root or from apps/api)
const envFilePath = path.join(__dirname, '..', '.env');

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath,
    }),
    PrismaModule,
    AuthModule,
    CategoriesModule,
    SettingsModule,
    AccountsModule,
    TransactionsModule,
    BudgetsModule,
    RulesModule,
    NotificationsModule,
    SyncModule,
    PlaidModule,
  ],
})
export class AppModule {}

