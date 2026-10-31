import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.personal)
}

export default function PersonalLayout({ children }: { children: React.ReactNode }) {
  return children
}
