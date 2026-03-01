import { IsString, IsNotEmpty } from 'class-validator';

export class ExchangePublicTokenDto {
  @IsString()
  @IsNotEmpty()
  public_token!: string;
}
