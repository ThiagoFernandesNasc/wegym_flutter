require('dotenv').config({ path: '.env.local' });
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const p = new PrismaClient();

async function main() {
  const email = 'test@test.com';
  const password = 'test123';
  const passwordHash = await bcrypt.hash(password, 10);
  
  const user = await p.user.create({
    data: {
      email,
      passwordHash,
      role: 'atleta',
      termsAcceptedAt: new Date(),
      privacyAcceptedAt: new Date(),
      dataConsentAt: new Date(),
      athlete: {
        create: {
          name: 'Test User',
          cpf: '12345678901',
          cep: '01310-100',
          city: 'São Paulo',
          state: 'SP',
          sex: 'masculino',
          experienceLevel: 'iniciante',
          age: 25,
          heightCm: 180,
          weightKg: 75,
        },
      },
    },
    select: { id: true, email: true, role: true },
  });
  
  console.log('User created:', user);
  await p.$disconnect();
}

main().catch(console.error);