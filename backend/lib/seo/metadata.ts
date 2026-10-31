import type { Metadata } from 'next'
import { getLocale, getDictionary } from '@/lib/i18n/server'
import { locales } from '@/lib/i18n/config'

type PageConfig = {
  titleKey: string
  descriptionKey: string
  path: string
}

function resolveT(obj: Record<string, unknown>, key: string): string {
  const parts = key.split('.')
  let current: unknown = obj
  for (const part of parts) {
    if (typeof current !== 'object' || current === null) return ''
    current = (current as Record<string, unknown>)[part]
  }
  return typeof current === 'string' ? current : ''
}

export async function generatePageMetadata(config: PageConfig): Promise<Metadata> {
  const locale = await getLocale()
  const dict = await getDictionary(locale)
  const fallbackDict = locale !== 'en' ? await getDictionary('en') : dict

  const title = resolveT(dict, config.titleKey) || resolveT(fallbackDict, config.titleKey) || 'WEGYM'
  const description = resolveT(dict, config.descriptionKey) || resolveT(fallbackDict, config.descriptionKey) || ''
  const appTitle = resolveT(dict, 'app.title') || 'WEGYM'

  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || process.env.NEXTAUTH_URL || 'http://localhost:3000'
  const url = `${baseUrl}${config.path}`
  const imageUrl = `${baseUrl}/og-image.png`

  return {
    title,
    description,
    openGraph: {
      title: `${title} | ${appTitle}`,
      description,
      url,
      siteName: appTitle,
      locale,
      type: 'website',
      images: [{ url: imageUrl, width: 1200, height: 630, alt: appTitle }],
    },
    twitter: {
      card: 'summary_large_image',
      title: `${title} | ${appTitle}`,
      description,
      images: [imageUrl],
    },
    alternates: { canonical: url },
  }
}

export const PAGE_CONFIGS: Record<string, PageConfig> = {
  root: { titleKey: 'app.title', descriptionKey: 'app.description', path: '/' },
  login: { titleKey: 'login.title', descriptionKey: 'login.description', path: '/login' },
  home: { titleKey: 'app.title', descriptionKey: 'home.description', path: '/home' },
  training: { titleKey: 'app.title', descriptionKey: 'training.description', path: '/training' },
  profile: { titleKey: 'profile.title', descriptionKey: 'profile.description', path: '/profile' },
  stats: { titleKey: 'stats.title', descriptionKey: 'stats.description', path: '/stats' },
  pro: { titleKey: 'pro.title', descriptionKey: 'pro.description', path: '/pro' },
  payment: { titleKey: 'payment.title', descriptionKey: 'payment.description', path: '/payment' },
  personal: { titleKey: 'app.title', descriptionKey: 'personal.description', path: '/personal' },
  privacy: { titleKey: 'privacy.title', descriptionKey: 'privacy.description', path: '/privacy' },
  resetPassword: { titleKey: 'resetPassword.title', descriptionKey: 'app.description', path: '/reset-password' },
  offline: { titleKey: 'offline.title', descriptionKey: 'app.description', path: '/offline' },
  notFound: { titleKey: 'notFound.title', descriptionKey: 'app.description', path: '/404' },
  goals: { titleKey: 'app.title', descriptionKey: 'goals.description', path: '/goals' },
  achievements: { titleKey: 'achievements.title', descriptionKey: 'achievements.description', path: '/achievements' },
  programs: { titleKey: 'programs.title', descriptionKey: 'programs.description', path: '/programs' },
  checkin: { titleKey: 'checkin.title', descriptionKey: 'checkin.description', path: '/checkin' },
  nutrition: { titleKey: 'nutrition.title', descriptionKey: 'nutrition.description', path: '/nutrition' },
  measurements: { titleKey: 'measurements.title', descriptionKey: 'measurements.description', path: '/measurements' },
}
