import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, TransactionStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ListTransactionsQueryDto } from './dto/list-transactions.query';
import { UpdateTransactionDto } from './dto/update-transaction.dto';

type TransactionWithRelations = {
  id: string;
  merchant_name: string;
  amount_cents: number;
  currency: string;
  status: TransactionStatus;
  effective_date: Date;
  posted_at: Date | null;
  is_excluded: boolean;
  account: { id: string; name: string; provider: string; type: string };
  category: { id: string; name: string; group: string } | null;
};

function toTransactionItem(t: TransactionWithRelations) {
  return {
    id: t.id,
    account: {
      id: t.account.id,
      name: t.account.name,
      provider: t.account.provider,
      type: t.account.type,
    },
    category: t.category
      ? { id: t.category.id, name: t.category.name, group: t.category.group }
      : null,
    merchant_name: t.merchant_name,
    amount_cents: t.amount_cents,
    currency: t.currency,
    status: t.status,
    effective_date: t.effective_date.toISOString(),
    posted_date: t.posted_at ? t.posted_at.toISOString() : null,
    is_excluded: t.is_excluded,
  };
}

@Injectable()
export class TransactionsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: ListTransactionsQueryDto) {
    const limit = Math.min(500, Math.max(1, query.limit ?? 100));
    const includeExcluded = query.includeExcluded ?? false;

    const where: Prisma.TransactionWhereInput = {
      user_id: userId,
    };

    if (query.accountId) where.account_id = query.accountId;
    if (query.status) where.status = query.status as TransactionStatus;
    if (query.categoryId) where.category_id = query.categoryId;
    if (!includeExcluded) where.is_excluded = false;
    if (query.q?.trim()) {
      where.merchant_name = { contains: query.q.trim(), mode: 'insensitive' };
    }

    if (query.month) {
      const [y, m] = query.month.split('-').map(Number);
      const start = new Date(y, m - 1, 1);
      const end = new Date(y, m, 0, 23, 59, 59, 999);
      where.effective_date = { gte: start, lte: end };
    } else {
      const now = new Date();
      const start = new Date(now.getFullYear(), now.getMonth(), 1);
      const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
      where.effective_date = { gte: start, lte: end };
    }

    let cursorDate: Date | null = null;
    let cursorId: string | null = null;
    if (query.cursor) {
      const cursorTx = await this.prisma.transaction.findFirst({
        where: { id: query.cursor, user_id: userId },
        select: { effective_date: true, id: true },
      });
      if (cursorTx) {
        cursorDate = cursorTx.effective_date;
        cursorId = cursorTx.id;
      }
    }

    if (cursorDate != null && cursorId != null) {
      where.OR = [
        { effective_date: { lt: cursorDate } },
        { effective_date: cursorDate, id: { lt: cursorId } },
      ];
    }

    const take = limit + 1;
    const rows = await this.prisma.transaction.findMany({
      where,
      orderBy: [{ effective_date: 'desc' }, { id: 'desc' }],
      take,
      include: {
        account: { select: { id: true, name: true, provider: true, type: true } },
        category: { select: { id: true, name: true, group: true } },
      },
    });

    const hasMore = rows.length > limit;
    const data = hasMore ? rows.slice(0, limit) : rows;
    const nextCursor = hasMore ? data[data.length - 1].id : undefined;

    return {
      data: (data as TransactionWithRelations[]).map(toTransactionItem),
      ...(nextCursor != null && { nextCursor }),
    };
  }

  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    const tx = await this.prisma.transaction.findFirst({
      where: { id, user_id: userId },
      include: {
        account: { select: { id: true, name: true, provider: true, type: true } },
        category: { select: { id: true, name: true, group: true } },
      },
    });
    if (!tx) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Transaction not found' });
    }

    const updateData: { category_id?: string | null; is_excluded?: boolean } = {};
    if (dto.category_id !== undefined) updateData.category_id = dto.category_id;
    if (dto.is_excluded !== undefined) updateData.is_excluded = dto.is_excluded;

    const updated = await this.prisma.transaction.update({
      where: { id },
      data: updateData,
      include: {
        account: { select: { id: true, name: true, provider: true, type: true } },
        category: { select: { id: true, name: true, group: true } },
      },
    });

    return toTransactionItem(updated);
  }
}
