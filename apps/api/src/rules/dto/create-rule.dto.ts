import { IsBoolean, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateRuleDto {
  @IsString()
  matchValue!: string;

  @IsString()
  categoryId!: string;

  @IsInt()
  @Min(0)
  priority!: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
