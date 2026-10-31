import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.pro)
}

export default function ProLayout({ children }: { children: React.ReactNode }) {
  return children
}
