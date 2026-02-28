import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { RulesService } from './rules.service';
import { CreateRuleDto } from './dto/create-rule.dto';
import { UpdateRuleDto } from './dto/update-rule.dto';

@UseGuards(JwtAuthGuard)
@Controller('rules')
export class RulesController {
  constructor(private readonly rulesService: RulesService) {}

  @Get()
  list(@User() user: JwtPayload) {
    return this.rulesService.listByUser(user.sub);
  }

  @Post()
  create(@User() user: JwtPayload, @Body() dto: CreateRuleDto) {
    return this.rulesService.create(user.sub, dto);
  }

  @Patch(':id')
  update(
    @User() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateRuleDto,
  ) {
    return this.rulesService.update(user.sub, id, dto);
  }

  @Delete(':id')
  remove(@User() user: JwtPayload, @Param('id') id: string) {
    return this.rulesService.remove(user.sub, id);
  }
}
