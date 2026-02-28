import { IsBoolean, IsOptional, IsUUID, ValidateIf } from 'class-validator';

export class UpdateTransactionDto {
  @IsOptional()
  @ValidateIf((_, v) => v != null)
  @IsUUID()
  category_id?: string | null;

  @IsOptional()
  @IsBoolean()
  is_excluded?: boolean;
}
