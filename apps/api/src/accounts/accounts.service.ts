import { Injectable } from '@nestjs/common';
import { AccountType, Provider } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AccountsService {
  constructor(private readonly prisma: PrismaService) {}

  listByUser(userId: string) {
    return this.prisma.connectedAccount.findMany({
      where: { user_id: userId },
      orderBy: { created_at: 'asc' },
    });
  }

  async ensureMockAccounts(userId: string) {
    const existing = await this.prisma.connectedAccount.findMany({
      where: { user_id: userId, provider: Provider.MOCK },
    });
    if (existing.length > 0) return existing;

    const accounts = [
      { name: 'Mock Checking', type: AccountType.CHECKING },
      { name: 'Mock Credit Card', type: AccountType.CREDIT },
      { name: 'Mock Debit', type: AccountType.DEBIT },
    ];

    const created = await Promise.all(
      accounts.map((a) =>
        this.prisma.connectedAccount.create({
          data: {
            user_id: userId,
            provider: Provider.MOCK,
            name: a.name,
            type: a.type,
          },
        }),
      ),
    );
    return created;
  }
}
