import { Controller, Post, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { SyncService } from './sync.service';

@UseGuards(JwtAuthGuard)
@Controller()
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('sync')
  sync(@User() user: JwtPayload) {
    return this.syncService.sync(user.sub);
  }
}
