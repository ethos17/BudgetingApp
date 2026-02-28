import { IsBoolean, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class UpdateRuleDto {
  @IsOptional()
  @IsString()
  matchValue?: string;

  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  priority?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
