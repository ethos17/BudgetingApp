import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  listByUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { user_id: userId },
      orderBy: { created_at: 'desc' },
    });
  }

  async markRead(userId: string, id: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id, user_id: userId },
    });
    if (!notification) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Notification not found' });
    }
    return this.prisma.notification.update({
      where: { id },
      data: { read_at: new Date() },
    });
  }
}
