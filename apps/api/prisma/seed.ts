import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

const DEMO_EMAIL = 'demo@ledgerlens.local';
const DEMO_PASSWORD = 'Password123!';

async function main() {
  const password_hash = await argon2.hash(DEMO_PASSWORD);

  const existing = await prisma.user.findUnique({ where: { email: DEMO_EMAIL } });
  if (existing) {
    await prisma.user.update({
      where: { email: DEMO_EMAIL },
      data: { password_hash },
    });
    console.log('Demo user already exists; password hash updated.');
    return;
  }

  await prisma.user.create({
    data: {
      email: DEMO_EMAIL,
      password_hash,
      include_pending_in_budget: false,
      notify_on_pending: false,
    },
  });

  console.log('Seed complete. Created demo user:', DEMO_EMAIL);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
