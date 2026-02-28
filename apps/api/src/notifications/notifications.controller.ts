import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { NotificationsService } from './notifications.service';

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  list(@User() user: JwtPayload) {
    return this.notificationsService.listByUser(user.sub);
  }

  @Post(':id/read')
  markRead(@User() user: JwtPayload, @Param('id') id: string) {
    return this.notificationsService.markRead(user.sub, id);
  }
}
