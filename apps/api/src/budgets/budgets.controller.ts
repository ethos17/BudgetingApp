import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { BudgetsService } from './budgets.service';
import { CreateBudgetDto } from './dto/create-budget.dto';
import { UpdateBudgetDto } from './dto/update-budget.dto';

@UseGuards(JwtAuthGuard)
@Controller('budgets')
export class BudgetsController {
  constructor(private readonly budgetsService: BudgetsService) {}

  @Get()
  list(@User() user: JwtPayload) {
    return this.budgetsService.listByUser(user.sub);
  }

  @Post()
  create(@User() user: JwtPayload, @Body() dto: CreateBudgetDto) {
    return this.budgetsService.create(user.sub, dto);
  }

  @Patch(':id')
  update(
    @User() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateBudgetDto,
  ) {
    return this.budgetsService.update(user.sub, id, dto);
  }
}
