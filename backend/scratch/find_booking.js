const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const booking = await prisma.seatBooking.findFirst({
    where: { paidAt: null, paymentMethod: null },
    select: { rideId: true, userId: true }
  });
  console.log(JSON.stringify(booking));
}

main().catch(console.error).finally(() => prisma.$disconnect());
