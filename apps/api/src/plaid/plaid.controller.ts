import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { PlaidService } from './plaid.service';
import { ExchangePublicTokenDto } from './dto/exchange-public-token.dto';

@UseGuards(JwtAuthGuard)
@Controller('plaid')
export class PlaidController {
  constructor(private readonly plaidService: PlaidService) {}

  @Post('link-token')
  async createLinkToken(@User() user: JwtPayload): Promise<{ link_token: string }> {
    return this.plaidService.createLinkToken(user.sub);
  }

  @Post('exchange')
  async exchange(@User() user: JwtPayload, @Body() dto: ExchangePublicTokenDto) {
    return this.plaidService.exchangePublicToken(user.sub, dto.public_token);
  }

  @Post('sync')
  async sync(@User() user: JwtPayload): Promise<{ added: number; modified: number; removed: number }> {
    return this.plaidService.syncTransactions(user.sub);
  }
}
