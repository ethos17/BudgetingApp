import { ConflictException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { LinkAccountDto } from './dto/link-account.dto';

@Injectable()
export class AccountsService {
  constructor(private readonly prisma: PrismaService) {}

  async listByUser(userId: string) {
    const accounts = await this.prisma.connectedAccount.findMany({
      where: { user_id: userId },
      orderBy: [{ provider: 'asc' }, { name: 'asc' }],
      select: {
        id: true,
        provider: true,
        name: true,
        type: true,
        created_at: true,
      },
    });
    return accounts.map((a) => ({
      id: a.id,
      provider: a.provider,
      name: a.name,
      type: a.type,
      created_at: a.created_at.toISOString(),
    }));
  }

  async linkAccount(userId: string, dto: LinkAccountDto) {
    const existing = await this.prisma.connectedAccount.findFirst({
      where: {
        user_id: userId,
        provider: dto.provider,
        name: dto.name,
      },
    });
    if (existing) {
      throw new ConflictException({
        code: 'CONFLICT',
        message: 'An account with this provider and name is already linked',
      });
    }
    const account = await this.prisma.connectedAccount.create({
      data: {
        user_id: userId,
        provider: dto.provider,
        name: dto.name,
        type: dto.type,
      },
      select: {
        id: true,
        provider: true,
        name: true,
        type: true,
        created_at: true,
      },
    });
    return {
      id: account.id,
      provider: account.provider,
      name: account.name,
      type: account.type,
      created_at: account.created_at.toISOString(),
    };
  }
}
