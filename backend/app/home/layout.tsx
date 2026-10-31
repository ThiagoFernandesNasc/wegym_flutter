import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.home)
}

export default function HomeLayout({ children }: { children: React.ReactNode }) {
  return children
}
