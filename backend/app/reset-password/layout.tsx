import { generatePageMetadata, PAGE_CONFIGS } from '@/lib/seo/metadata'

export async function generateMetadata() {
  return generatePageMetadata(PAGE_CONFIGS.resetPassword)
}

export default function ResetPasswordLayout({ children }: { children: React.ReactNode }) {
  return children
}
