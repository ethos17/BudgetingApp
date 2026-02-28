import { Injectable } from '@nestjs/common';
import { AccountType, ConnectedAccount, Provider } from '@prisma/client';
import {
  FinancialDataProvider,
  ProviderSyncResult,
  ProviderTransaction,
} from './financial-data.provider';

function seededRandom(seed: number) {
  return () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 0xffffffff;
  };
}

@Injectable()
export class MockFinancialDataProvider implements FinancialDataProvider {
  async sync(
    userId: string,
    accounts: ConnectedAccount[],
    options: { since?: Date; until?: Date },
  ): Promise<ProviderSyncResult> {
    const until = options.until ?? new Date();
    const since = options.since ?? new Date(until.getTime() - 90 * 24 * 60 * 60 * 1000);
    const days = Math.ceil((until.getTime() - since.getTime()) / (24 * 60 * 60 * 1000)) + 1;

    const seed = this.hashString(userId);
    const rng = seededRandom(seed);

    const merchantsByType: Record<AccountType, string[]> = {
      CHECKING: ['Whole Foods', "Trader Joe's", 'Payroll Inc.', 'Electric Co', 'Gas Co', 'Target'],
      DEBIT: ['Starbucks', 'Uber', 'Lyft', 'Costco', 'Amazon'],
      CREDIT: ['Netflix', 'Spotify', 'Uber', 'Target', 'Amazon'],
    };

    const transactions: ProviderTransaction[] = [];

    for (const account of accounts) {
      const merchants = merchantsByType[account.type] ?? merchantsByType.CHECKING;
      for (let i = 0; i < days; i++) {
        const day = new Date(until);
        day.setDate(day.getDate() - i);
        if (day < since) continue;

        const count = 1 + Math.floor(rng() * 3);
        for (let j = 0; j < count; j++) {
          const merchant = merchants[Math.floor(rng() * merchants.length)];
          const amount = Math.floor(rng() * 20000) + 500;
          const isIncome = merchant === 'Payroll Inc.';
          const signed = isIncome ? amount : -amount;
          const status: 'PENDING' | 'POSTED' = i <= 2 && rng() < 0.6 ? 'PENDING' : 'POSTED';
          const effective = new Date(day);
          effective.setHours(Math.floor(rng() * 23), Math.floor(rng() * 59), 0, 0);

          const baseId = `${account.id}_${effective.toISOString().slice(0, 10)}_${j}`;
          let merchantName = merchant;
          if (status === 'PENDING' && rng() < 0.2) merchantName = `${merchant} PENDING`;
          const provider_pending_id = status === 'PENDING' ? `P_${baseId}` : undefined;
          const provider_transaction_id = status === 'POSTED' ? `T_${baseId}` : undefined;

          transactions.push({
            accountId: account.id,
            amount_cents: signed,
            currency: 'USD',
            authorized_at: status === 'PENDING' ? effective : null,
            posted_at: status === 'POSTED' ? effective : null,
            effective_date: effective,
            merchant_name: merchantName,
            description: `${merchant} transaction`,
            status,
            provider: Provider.MOCK,
            provider_pending_id,
            provider_transaction_id,
            metadata: { seed: baseId },
          });
        }
      }
    }

    return { transactions };
  }

  private hashString(s: string): number {
    let h = 0;
    for (let i = 0; i < s.length; i++) {
      h = ((h << 5) - h + s.charCodeAt(i)) | 0;
    }
    return h || 1;
  }
}
