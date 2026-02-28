import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { TransactionsService } from './transactions.service';
import { ListTransactionsQueryDto } from './dto/list-transactions.query';
import { UpdateTransactionDto } from './dto/update-transaction.dto';

@UseGuards(JwtAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Get()
  list(@User() user: JwtPayload, @Query() query: ListTransactionsQueryDto) {
    return this.transactionsService.list(user.sub, query);
  }

  @Patch(':id')
  update(
    @User() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateTransactionDto,
  ) {
    return this.transactionsService.update(user.sub, id, dto);
  }
}
