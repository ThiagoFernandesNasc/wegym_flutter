import "./globals.css";
import { SessionProviderWrapper } from "@/components/providers/SessionProviderWrapper";
import { AppShell } from "@/components/ui/AppShell";
import { PwaSync } from "@/components/PwaSync";
import { ConsentBanner } from "@/components/lgpd/ConsentBanner";
import { I18nWrapper } from "@/components/i18n/I18nWrapper";
import { Toaster } from "sonner";

const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || process.env.NEXTAUTH_URL || 'http://localhost:3000'

export const metadata = {
  metadataBase: new URL(baseUrl),
  title: {
    default: "WEGYM",
    template: "%s | WEGYM",
  },
  description: "Plataforma de treinos inteligente — academia, cardio e performance",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    title: "WEGYM",
    statusBarStyle: "black-translucent",
  },
  icons: [
    { rel: "icon", url: "/icon-192.png" },
    { rel: "apple-touch-icon", url: "/icon-192.png" },
  ],
  openGraph: {
    title: "WEGYM",
    description: "Plataforma de treinos inteligente — academia, cardio e performance",
    url: baseUrl,
    siteName: "WEGYM",
    locale: "pt_BR",
    type: "website",
    images: [{ url: "/og-image.png", width: 1200, height: 630, alt: "WEGYM" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "WEGYM",
    description: "Plataforma de treinos inteligente — academia, cardio e performance",
    images: ["/og-image.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
  alternates: {
    defaults: [{ languages: ['en', 'es', 'fr', 'de', 'it', 'pt-BR'] }],
  },
};

// ... rest of the file

export const viewport = {
  themeColor: "#ea580c",
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const jsonLd = {
    "@context": "https://schema.org",
      "@type": "WebApplication",
    name: "WEGYM",
    description: "Plataforma de treinos inteligente — academia, cardio e performance",
    url: baseUrl,
    applicationCategory: "HealthApplication",
    operatingSystem: "Web, iOS, Android",
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "BRL",
    },
  }

  return (
    <html lang="pt-BR">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=yes, viewport-fit=cover" />
        <meta name="theme-color" content="#ea580c" />
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="msapplication-tap-highlight" content="no" />
        <link rel="manifest" href="/manifest.json" />
        <link rel="icon" type="image/png" href="/icon-192.png" />
        <link rel="apple-touch-icon" href="/icon-192.png" />
        <link rel="shortcut icon" href="/icon-192.png" />
        <meta name="apple-mobile-web-app-title" content="WEGYM" />
        {/* Hreflang tags for SEO */}
        <link rel="alternate" hrefLang="pt-BR" href={`${baseUrl}/`} />
        <link rel="alternate" hrefLang="en" href={`${baseUrl}/en`} />
        <link rel="alternate" hrefLang="es" href={`${baseUrl}/es`} />
        <link rel="alternate" hrefLang="fr" href={`${baseUrl}/fr`} />
        <link rel="alternate" hrefLang="de" href={`${baseUrl}/de`} />
        <link rel="alternate" hrefLang="it" href={`${baseUrl}/it`} />
        <link rel="preconnect" href="https://ui-avatars.com" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link rel="dns-prefetch" href="https://ui-avatars.com" />
        <link rel="dns-prefetch" href="https://cdn.jsdelivr.net" />
        <link rel="dns-prefetch" href="https://fonts.googleapis.com" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
<body className="overscroll-none touch-callout-none">
        <a href="#main-content" className="skip-link visually-hidden focus-visible:focus focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:orange-500">
          Pular para o conteúdo principal
        </a>
        <I18nWrapper>
          <SessionProviderWrapper>
            <AppShell>{children}</AppShell>
          </SessionProviderWrapper>
          <ConsentBanner />
          <PwaSync />
        </I18nWrapper>
        <Toaster theme="dark" />
<script dangerouslySetInnerHTML={{__html: `(function(){if('caches' in window){caches.keys().then((keys)=>{keys.forEach((key)=>{caches.delete(key)})})}const ls=localStorage;ls.removeItem('__NEXT_DATA__');const ss=sessionStorage;ss.removeItem('__NEXT_DATA__')})()`}}
        />
      </body>
    </html>
  );
}
