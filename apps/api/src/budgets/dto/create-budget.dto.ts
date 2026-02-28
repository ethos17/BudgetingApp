import { IsBoolean, IsInt, IsOptional, IsPositive, IsString, Length } from 'class-validator';

export class CreateBudgetDto {
  @IsString()
  categoryId!: string;

  @IsString()
  @Length(7, 7, { message: 'month must be YYYY-MM' })
  month!: string;

  @IsInt()
  @IsPositive()
  limitCents!: number;

  @IsOptional()
  @IsBoolean()
  thresholdsEnabled?: boolean;
}
