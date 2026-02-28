import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateTransactionDto {
  @IsOptional()
  @IsString()
  categoryId?: string;

  @IsOptional()
  @IsBoolean()
  isExcluded?: boolean;
}
