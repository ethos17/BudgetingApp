import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GetTransactionsQueryDto } from './dto/get-transactions.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';

@Injectable()
export class TransactionsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: GetTransactionsQueryDto) {
    const page = Math.max(1, query.page ?? 1);
    const pageSize = Math.min(100, Math.max(1, query.pageSize ?? 50));

    const where: { user_id: string; effective_date?: { gte?: Date; lte?: Date }; status?: any; category_id?: string } = {
      user_id: userId,
    };

    if (query.startDate) {
      where.effective_date = { ...where.effective_date, gte: new Date(query.startDate) };
    }
    if (query.endDate) {
      where.effective_date = { ...where.effective_date, lte: new Date(query.endDate) };
    }
    if (query.status) where.status = query.status;
    if (query.categoryId) where.category_id = query.categoryId;

    const [data, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where,
        orderBy: { effective_date: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.transaction.count({ where }),
    ]);

    return {
      data,
      meta: { total, page, pageSize },
    };
  }

  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    const tx = await this.prisma.transaction.findFirst({
      where: { id, user_id: userId },
    });
    if (!tx) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Transaction not found' });
    }

    const data: { category_id?: string; is_excluded?: boolean } = {};
    if (dto.categoryId !== undefined) data.category_id = dto.categoryId;
    if (dto.isExcluded !== undefined) data.is_excluded = dto.isExcluded;

    return this.prisma.transaction.update({
      where: { id },
      data,
    });
  }
}
