import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { AccountsService } from './accounts.service';

@UseGuards(JwtAuthGuard)
@Controller('accounts')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  list(@User() user: JwtPayload) {
    return this.accountsService.listByUser(user.sub);
  }

  @Post('mock-link')
  mockLink(@User() user: JwtPayload) {
    return this.accountsService.ensureMockAccounts(user.sub);
  }
}
