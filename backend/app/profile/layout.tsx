import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.profile)
}

export default function ProfileLayout({ children }: { children: React.ReactNode }) {
  return children
}
