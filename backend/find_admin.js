const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    where: {
      OR: [
        { email: { contains: 'admin1' } },
        { name: { contains: 'admin1' } }
      ]
    }
  });
  console.log(users);
}
main().finally(() => prisma.$disconnect());
