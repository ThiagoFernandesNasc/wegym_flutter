import type { NextConfig } from 'next';

const isDev = process.env.NODE_ENV === 'development';
const corsAllowedOrigin = process.env.CORS_ALLOWED_ORIGIN ??
  (isDev ? '*' : '');

const nextConfig: NextConfig = {
  poweredByHeader: false,

  turbopack: {
    root: __dirname,
  },

  output: 'standalone',

  serverExternalPackages: ['@prisma/client', 'bcryptjs'],

  compress: true,

  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'ui-avatars.com',
        pathname: '/api/**',
      },
      {
        protocol: 'https',
        hostname: 'picsum.photos',
        pathname: '/**',
      },
    ],
    formats: ['image/webp', 'image/avif'],
    dangerouslyAllowSVG: false,
    contentSecurityPolicy: "default-src 'self'; script-src 'self'; sandbox;",
  },

  experimental: {
    optimizeServerReact: true,
    turbopackFileSystemCacheForDev: true,
  },

  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          ...(corsAllowedOrigin
            ? [{ key: 'Access-Control-Allow-Origin', value: corsAllowedOrigin }]
            : []),
          { key: 'Access-Control-Allow-Methods', value: 'GET, POST, PUT, PATCH, DELETE, OPTIONS' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type, Authorization, x-wegym-preview-ai' },
          { key: 'Access-Control-Max-Age', value: '600' },
        ],
      },
      {
        source: '/sw.js',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=0, must-revalidate' },
          { key: 'Service-Worker-Allowed', value: '/' },
        ],
      },
      {
        source: '/manifest.json',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=3600' },
          { key: 'Content-Type', value: 'application/manifest+json' },
        ],
      },
      {
        source: '/icon-:size.png',
        headers: [
          { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
        ],
      },
      {
        source: '/:path*',
        headers: [
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'Cache-Control', value: 'no-cache, no-store, must-revalidate' },
          { key: 'Pragma', value: 'no-cache' },
          { key: 'Expires', value: '0' },
          { key: 'Content-Security-Policy', value: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; worker-src 'self' blob:; style-src 'self'; img-src 'self' data: https:; connect-src 'self' api.mercadopago.com api.resend.com viacep.com.br *.ingest.us.sentry.io raw.githubusercontent.com cdn.jsdelivr.net ui-avatars.com; frame-src 'none'; frame-ancestors 'none'; object-src 'none'; font-src 'self' data:" },
          { key: 'Link', value: '<https://fonts.googleapis.com>; rel=preconnect' },
          { key: 'Link', value: '<https://fonts.gstatic.com>; rel=preconnect; crossorigin' },
          { key: 'Link', value: '<https://ui-avatars.com>; rel=preconnect' },
          { key: 'Link', value: '<https://cdn.jsdelivr.net>; rel=dns-prefetch' },
          { key: 'Link', value: '<https://api.mercadopago.com>; rel=dns-prefetch' },
          { key: 'Link', value: '<https://api.resend.com>; rel=dns-prefetch' },
          { key: 'Link', value: '<https://viacep.com.br>; rel=dns-prefetch' },
          { key: 'Link', value: '<https://*.ingest.us.sentry.io>; rel=dns-prefetch' },
          { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains; preload' },
          {
            key: 'Permissions-Policy',
            value: 'bluetooth=(self), camera=(), microphone=(), geolocation=(), payment=(), midi=(), sync-xhr=()',
          },
        ],
      },
    ];
  },
};

export default process.env.ANALYZE === 'true'
  // eslint-disable-next-line @typescript-eslint/no-require-imports -- The analyzer is optional and loaded only when requested.
  ? require('@next/bundle-analyzer')({ enabled: true })(nextConfig)
  : nextConfig;
