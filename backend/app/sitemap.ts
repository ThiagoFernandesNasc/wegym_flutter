import type { MetadataRoute } from 'next'

const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || process.env.NEXTAUTH_URL || 'http://localhost:3000'

const routes = [
  { path: '/', priority: 1.0, changeFrequency: 'monthly' as const },
  { path: '/login', priority: 0.8, changeFrequency: 'monthly' as const },
  { path: '/home', priority: 0.6, changeFrequency: 'weekly' as const },
  { path: '/training', priority: 0.6, changeFrequency: 'weekly' as const },
  { path: '/profile', priority: 0.5, changeFrequency: 'monthly' as const },
  { path: '/stats', priority: 0.5, changeFrequency: 'weekly' as const },
  { path: '/pro', priority: 0.7, changeFrequency: 'monthly' as const },
  { path: '/payment', priority: 0.5, changeFrequency: 'monthly' as const },
  { path: '/personal', priority: 0.6, changeFrequency: 'weekly' as const },
  { path: '/privacy', priority: 0.4, changeFrequency: 'yearly' as const },
  { path: '/reset-password', priority: 0.1, changeFrequency: 'monthly' as const },
  { path: '/offline', priority: 0.1, changeFrequency: 'monthly' as const },
  { path: '/goals', priority: 0.5, changeFrequency: 'weekly' as const },
  { path: '/achievements', priority: 0.3, changeFrequency: 'monthly' as const },
  { path: '/programs', priority: 0.5, changeFrequency: 'weekly' as const },
  { path: '/checkin', priority: 0.5, changeFrequency: 'weekly' as const },
  { path: '/nutrition', priority: 0.5, changeFrequency: 'weekly' as const },
  { path: '/measurements', priority: 0.3, changeFrequency: 'monthly' as const },
]

export default function sitemap(): MetadataRoute.Sitemap {
  return routes.map((route) => ({
    url: `${baseUrl}${route.path}`,
    lastModified: new Date(),
    changeFrequency: route.changeFrequency,
    priority: route.priority,
  }))
}
