import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateSettingsDto {
  @IsOptional()
  @IsBoolean()
  include_pending_in_budget?: boolean;

  @IsOptional()
  @IsBoolean()
  notify_on_pending?: boolean;
}
