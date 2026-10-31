import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.login)
}

export default function LoginLayout({ children }: { children: React.ReactNode }) {
  return children
}
