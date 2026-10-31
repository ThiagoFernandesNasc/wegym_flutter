import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.privacy)
}

export default function PrivacyLayout({ children }: { children: React.ReactNode }) {
  return children
}
