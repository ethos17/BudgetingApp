import { IsEnum, IsString, MinLength } from 'class-validator';
import { AccountType, Provider } from '@prisma/client';

export class LinkAccountDto {
  @IsEnum(Provider)
  provider!: Provider;

  @IsString()
  @MinLength(1)
  name!: string;

  @IsEnum(AccountType)
  type!: AccountType;
}
