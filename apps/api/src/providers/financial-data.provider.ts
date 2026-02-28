import { ConnectedAccount } from '@prisma/client';

export const FINANCIAL_DATA_PROVIDER = 'FINANCIAL_DATA_PROVIDER';

export interface ProviderTransaction {
  accountId: string;
  amount_cents: number;
  currency: string;
  authorized_at?: Date | null;
  posted_at?: Date | null;
  effective_date: Date;
  merchant_name: string;
  description?: string | null;
  status: 'PENDING' | 'POSTED';
  provider: 'MOCK' | 'CHASE' | 'SOFI' | 'DISCOVER';
  provider_transaction_id?: string | null;
  provider_pending_id?: string | null;
  metadata?: unknown;
}

export interface ProviderSyncResult {
  transactions: ProviderTransaction[];
}

export interface FinancialDataProvider {
  sync(
    userId: string,
    accounts: ConnectedAccount[],
    options: { since?: Date; until?: Date },
  ): Promise<ProviderSyncResult>;
}
