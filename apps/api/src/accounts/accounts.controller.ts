import { Body, Controller, Get, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { AccountsService } from './accounts.service';
import { LinkAccountDto } from './dto/link-account.dto';

@UseGuards(JwtAuthGuard)
@Controller('accounts')
export class AccountsController {
  constructor(private readonly accountsService: AccountsService) {}

  @Get()
  list(@User() user: JwtPayload) {
    return this.accountsService.listByUser(user.sub);
  }

  @Post('mock-link')
  @HttpCode(HttpStatus.CREATED)
  async mockLink(@User() user: JwtPayload, @Body() dto: LinkAccountDto) {
    const account = await this.accountsService.linkAccount(user.sub, dto);
    return account;
  }
}
