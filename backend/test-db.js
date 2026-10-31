require('dotenv').config({ path: '.env.local' });
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();
p.user.findMany({ select: { email: true, role: true, passwordHash: true } })
  .then(console.log)
  .catch(console.error)
  .finally(() => p.$disconnect());