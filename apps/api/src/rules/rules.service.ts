import { Injectable, NotFoundException } from '@nestjs/common';
import { RuleMatchType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRuleDto } from './dto/create-rule.dto';
import { UpdateRuleDto } from './dto/update-rule.dto';

@Injectable()
export class RulesService {
  constructor(private readonly prisma: PrismaService) {}

  listByUser(userId: string) {
    return this.prisma.rule.findMany({
      where: { user_id: userId },
      orderBy: { priority: 'asc' },
      include: { category: true },
    });
  }

  async create(userId: string, dto: CreateRuleDto) {
    return this.prisma.rule.create({
      data: {
        user_id: userId,
        match_type: RuleMatchType.MERCHANT_CONTAINS,
        match_value: dto.matchValue,
        category_id: dto.categoryId,
        priority: dto.priority,
        is_active: dto.isActive ?? true,
      },
      include: { category: true },
    });
  }

  async update(userId: string, id: string, dto: UpdateRuleDto) {
    const rule = await this.prisma.rule.findFirst({
      where: { id, user_id: userId },
    });
    if (!rule) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Rule not found' });
    }

    const data: { match_value?: string; category_id?: string; priority?: number; is_active?: boolean } = {};
    if (dto.matchValue !== undefined) data.match_value = dto.matchValue;
    if (dto.categoryId !== undefined) data.category_id = dto.categoryId;
    if (dto.priority !== undefined) data.priority = dto.priority;
    if (dto.isActive !== undefined) data.is_active = dto.isActive;

    return this.prisma.rule.update({
      where: { id },
      data,
      include: { category: true },
    });
  }

  async remove(userId: string, id: string) {
    const rule = await this.prisma.rule.findFirst({
      where: { id, user_id: userId },
    });
    if (!rule) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Rule not found' });
    }
    await this.prisma.rule.delete({ where: { id } });
    return { success: true };
  }
}
