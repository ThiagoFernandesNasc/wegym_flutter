// Configure test-only values before Vitest imports route modules that create Prisma.
const configuredDatabaseUrl = process.env.DATABASE_URL;
process.env.DATABASE_URL = configuredDatabaseUrl
  ? configuredDatabaseUrl.replace('/wegym?', '/wegym_test?')
  : 'postgresql://postgres:password@localhost:5432/wegym_test?schema=public';
process.env.NEXTAUTH_SECRET = 'test-secret';
process.env.NEXTAUTH_URL = 'http://localhost:3000';
Object.defineProperty(process.env, 'NODE_ENV', {
  value: 'test',
  writable: true,
  enumerable: true,
  configurable: true,
});
