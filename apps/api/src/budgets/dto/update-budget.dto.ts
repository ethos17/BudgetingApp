import { IsBoolean, IsInt, IsOptional, IsPositive } from 'class-validator';

export class UpdateBudgetDto {
  @IsOptional()
  @IsInt()
  @IsPositive()
  limitCents?: number;

  @IsOptional()
  @IsBoolean()
  thresholdsEnabled?: boolean;
}
