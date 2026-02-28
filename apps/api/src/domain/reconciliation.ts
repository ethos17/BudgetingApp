import { ProviderTransaction } from '../providers/financial-data.provider';

export interface ExistingTransaction {
  id: string;
  account_id: string;
  amount_cents: number;
  effective_date: Date;
  merchant_name: string;
  status: string;
  provider_transaction_id: string | null;
  provider_pending_id: string | null;
}

export interface ReconciliationResult {
  toCreate: Array<Omit<ProviderTransaction, 'accountId'> & { account_id: string }>;
  toUpdate: Array<{ id: string; status?: string; provider_transaction_id?: string | null; merchant_name?: string }>;
}

const THREE_DAYS_MS = 3 * 24 * 60 * 60 * 1000;

function norm(s: string): string {
  return s.toUpperCase().replace(/\s+/g, ' ').replace(/\bPENDING\b/g, '').trim();
}

export function reconcile(
  existing: ExistingTransaction[],
  incoming: ProviderTransaction[],
): ReconciliationResult {
  const byProviderId = new Map<string, ExistingTransaction>();
  for (const e of existing) {
    if (e.provider_transaction_id) byProviderId.set(e.provider_transaction_id, e);
    if (e.provider_pending_id) byProviderId.set(e.provider_pending_id, e);
  }

  const used = new Set<string>();
  const toCreate: ReconciliationResult['toCreate'] = [];
  const toUpdate: ReconciliationResult['toUpdate'] = [];

  for (const inc of incoming) {
    let match: ExistingTransaction | undefined;
    if (inc.provider_transaction_id) {
      const e = byProviderId.get(inc.provider_transaction_id);
      if (e && !used.has(e.id)) match = e;
    }
    if (!match && inc.provider_pending_id) {
      const e = byProviderId.get(inc.provider_pending_id);
      if (e && !used.has(e.id)) match = e;
    }
    if (!match) {
      const incTime = inc.effective_date.getTime();
      const incNorm = norm(inc.merchant_name);
      match = existing.find((e) => {
        if (used.has(e.id)) return false;
        if (e.account_id !== inc.accountId) return false;
        if (e.amount_cents !== inc.amount_cents) return false;
        const eTime = e.effective_date.getTime();
        if (Math.abs(eTime - incTime) > THREE_DAYS_MS) return false;
        if (norm(e.merchant_name) !== incNorm) return false;
        return true;
      });
    }

    if (!match) {
      toCreate.push({
        ...inc,
        account_id: inc.accountId,
      });
      continue;
    }

    used.add(match.id);
    const updates: ReconciliationResult['toUpdate'][0] = { id: match.id };
    if (inc.status !== match.status) updates.status = inc.status;
    if (inc.provider_transaction_id && !match.provider_transaction_id) updates.provider_transaction_id = inc.provider_transaction_id;
    if (inc.merchant_name !== match.merchant_name) updates.merchant_name = inc.merchant_name;
    if (Object.keys(updates).length > 1) toUpdate.push(updates);
  }

  return { toCreate, toUpdate };
}
