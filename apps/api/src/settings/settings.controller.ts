import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { User } from '../common/decorators/user.decorator';
import { JwtPayload } from '../common/types/request-with-user';
import { JwtAuthGuard } from '../auth/auth.guard';
import { SettingsService } from './settings.service';
import { UpdateSettingsDto } from './dto/update-settings.dto';

@UseGuards(JwtAuthGuard)
@Controller('settings')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  @Get()
  get(@User() user: JwtPayload) {
    return this.settingsService.get(user.sub);
  }

  @Patch()
  update(@User() user: JwtPayload, @Body() dto: UpdateSettingsDto) {
    return this.settingsService.update(user.sub, dto);
  }
}
