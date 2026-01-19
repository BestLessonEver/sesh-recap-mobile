import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { DashboardLayout } from '@/components/dashboard-layout'

export default async function DashboardGroupLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/auth/login')
  }

  // Get professional data
  const { data: professional } = await supabase
    .from('professionals')
    .select('id, name, email, role')
    .eq('id', user.id)
    .single()

  return (
    <DashboardLayout professional={professional}>
      {children}
    </DashboardLayout>
  )
}
