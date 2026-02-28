import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { UpdateBudgetDto } from './dto/update-budget.dto';

@Injectable()
export class BudgetsService {
  constructor(private readonly prisma: PrismaService) {}

  listByUser(userId: string) {
    return this.prisma.budget.findMany({
      where: { user_id: userId },
      orderBy: [{ month: 'desc' }, { category_id: 'asc' }],
      include: { category: true },
    });
  }

  async create(userId: string, dto: CreateBudgetDto) {
    return this.prisma.budget.upsert({
      where: {
        user_id_category_id_month: {
          user_id: userId,
          category_id: dto.categoryId,
          month: dto.month,
        },
      },
      create: {
        user_id: userId,
        category_id: dto.categoryId,
        month: dto.month,
        limit_cents: dto.limitCents,
        thresholds_enabled: dto.thresholdsEnabled ?? true,
      },
      update: {
        limit_cents: dto.limitCents,
        ...(dto.thresholdsEnabled !== undefined && { thresholds_enabled: dto.thresholdsEnabled }),
      },
      include: { category: true },
    });
  }

  async update(userId: string, id: string, dto: UpdateBudgetDto) {
    const budget = await this.prisma.budget.findFirst({
      where: { id, user_id: userId },
    });
    if (!budget) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Budget not found' });
    }

    const data: { limit_cents?: number; thresholds_enabled?: boolean } = {};
    if (dto.limitCents !== undefined) data.limit_cents = dto.limitCents;
    if (dto.thresholdsEnabled !== undefined) data.thresholds_enabled = dto.thresholdsEnabled;

    return this.prisma.budget.update({
      where: { id },
      data,
      include: { category: true },
    });
  }
}
