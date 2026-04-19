const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function testPrisma() {
  try {
    const documentType = "NID";
    const reqFileName = "test.png";
    const parsedData = { rawText: "", extractedFields: { nidNumber: null, fullName: null, dateOfBirth: null, address: null } };
    const userId = 1;

    const verificationRequest = await prisma.verificationRequest.create({
      data: {
        userId: userId,
        documentType: documentType,
        documentPath: reqFileName,
        extractedData: parsedData,
        status: "PENDING",
      },
    });
    console.log("Success", verificationRequest);
  } catch (error) {
    console.error("Error creating record:");
    console.error(error);
  } finally {
    await prisma.$disconnect();
  }
}

testPrisma();
