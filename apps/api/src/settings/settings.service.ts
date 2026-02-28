import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class SettingsService {
  constructor(private readonly prisma: PrismaService) {}

  async get(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        include_pending_in_budget: true,
        notify_on_pending: true,
      },
    });
    if (!user) return { include_pending_in_budget: false, notify_on_pending: false };
    return user;
  }

  async update(userId: string, dto: UpdateSettingsDto) {
    const data: { include_pending_in_budget?: boolean; notify_on_pending?: boolean } = {};
    if (dto.include_pending_in_budget !== undefined) data.include_pending_in_budget = dto.include_pending_in_budget;
    if (dto.notify_on_pending !== undefined) data.notify_on_pending = dto.notify_on_pending;
    const user = await this.prisma.user.update({
      where: { id: userId },
      data,
      select: {
        include_pending_in_budget: true,
        notify_on_pending: true,
      },
    });
    return user;
  }
}
