'use client'

import { useI18n } from './provider'

export function useTranslations() {
  const { t, locale, changeLocale, dir } = useI18n()

  return {
    t,
    locale,
    changeLocale,
    dir,
  } as const
}
