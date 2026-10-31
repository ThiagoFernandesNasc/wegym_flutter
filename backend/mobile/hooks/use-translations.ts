import AsyncStorage from "@react-native-async-storage/async-storage";
import ptBR from "@/i18n/pt-br";
import type { Translations } from "@/i18n/pt-br";

const LOCALE_KEY = "wegym_locale";
let currentLocale = "pt-BR";
let translations: Translations = ptBR;

export function setLocale(locale: string) {
  currentLocale = locale;
  try { AsyncStorage.setItem(LOCALE_KEY, locale); } catch {}
}

export async function loadLocale() {
  try {
    const stored = await AsyncStorage.getItem(LOCALE_KEY);
    if (stored) currentLocale = stored;
  } catch {}
}

function localeToFile(locale: string): string {
  const map: Record<string, string> = {
    "pt-BR": "pt-BR",
    "en": "en",
    "es": "es",
    "fr": "fr",
    "de": "de",
    "it": "it",
    "ar": "ar",
    "ja": "ja",
    "ko": "ko",
    "nl": "nl",
    "pl": "pl",
    "ru": "ru",
    "tr": "tr",
    "zh-CN": "zh-CN",
    "hi": "hi",
  };
  return map[locale] ?? "pt-BR";
}

async function loadTranslations(locale: string): Promise<Translations> {
  const file = localeToFile(locale);
  try {
    const mod = await import(`@/translations/${file}.json`);
    return mod.default ?? mod;
  } catch {
    return ptBR;
  }
}

export async function loadAndSetLocale(locale: string) {
  currentLocale = locale;
  translations = await loadTranslations(locale);
  try { await AsyncStorage.setItem(LOCALE_KEY, locale); } catch {}
}

export function useT(): Translations {
  return translations;
}

export function t(key: string): string {
  const parts = key.split(".");
  let result: Record<string, unknown> = translations as unknown as Record<string, unknown>;
  for (const part of parts) {
    result = result[part] as Record<string, unknown>;
  }
  return (result as unknown as string) ?? key;
}

export { translations as ptBR };
