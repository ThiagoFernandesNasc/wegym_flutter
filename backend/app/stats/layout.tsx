import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.stats)
}

export default function StatsLayout({ children }: { children: React.ReactNode }) {
  return children
}
