import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.offline)
}

export default function OfflineLayout({ children }: { children: React.ReactNode }) {
  return children
}
