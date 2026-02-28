import { IsBoolean, IsEnum, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { TransactionStatus } from '@prisma/client';

function toBool(value: unknown): boolean {
  if (value === true || value === 'true') return true;
  return false;
}

export class ListTransactionsQueryDto {
  @IsOptional()
  @IsString()
  month?: string; // YYYY-MM

  @IsOptional()
  @IsUUID()
  accountId?: string;

  @IsOptional()
  @IsEnum(TransactionStatus)
  status?: TransactionStatus;

  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @Type(() => Boolean)
  @Transform(({ value }) => toBool(value))
  @IsBoolean()
  includeExcluded?: boolean = false;

  @IsOptional()
  @Type(() => Number)
  @Min(1)
  @Max(500)
  limit?: number = 100;

  @IsOptional()
  @IsString()
  cursor?: string;
}
