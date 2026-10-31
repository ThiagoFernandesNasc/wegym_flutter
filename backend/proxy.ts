import { withAuth } from 'next-auth/middleware';

export default withAuth({
  callbacks: {
    authorized: ({ token, req }) => {
      const path = req.nextUrl.pathname;

      if (req.method === 'OPTIONS') return true;

      // The Flutter/Expo APIs authenticate their own Bearer tokens in each route.
      // Let those requests reach the route handler; a malformed token still gets 401 there.
      if (path.startsWith('/api/') && req.headers.get('authorization')?.startsWith('Bearer ')) {
        return true;
      }

      if (path === '/' || path === '/login' || path === '/offline' || path === '/privacy' || path === '/reset-password') {
        return true;
      }

      if (path.startsWith('/sentry-example')) return false;
      if (path.startsWith('/api/sentry-example')) return false;
      if (path.startsWith('/api/auth')) return true;
      if (path.startsWith('/api/webhooks')) return true;
      if (path === '/api/health') return true;

      return !!token;
    },
  },
});

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|icon-.*\\.png|manifest.json|sw\\.js|robots\\.txt|sitemap\\.xml).*)',
  ],
};
