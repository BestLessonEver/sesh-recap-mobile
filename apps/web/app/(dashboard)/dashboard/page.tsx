import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { Clock, Users, CreditCard } from 'lucide-react'
import type { ProfessionalWithOrg, SessionWithRelations } from '@/types/database'
import { getSessionStatusClass, getRecapStatusClass, getRecapStatusLabel } from '@/lib/utils'

export default async function DashboardPage() {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Get professional data
  const { data: professional } = await supabase
    .from('professionals')
    .select('*, organization:organizations(*)')
    .eq('id', user!.id)
    .single() as { data: ProfessionalWithOrg | null }

  // Get recent sessions
  const { data: sessions } = await supabase
    .from('sessions')
    .select('*, client:attendants!attendant_id(*), recap:recaps(*)')
    .eq('professional_id', user!.id)
    .order('created_at', { ascending: false })
    .limit(5) as { data: SessionWithRelations[] | null }

  // Get stats
  const { count: totalSessions } = await supabase
    .from('sessions')
    .select('*', { count: 'exact', head: true })
    .eq('professional_id', user!.id)

  const { count: totalClients } = await supabase
    .from('attendants')
    .select('*', { count: 'exact', head: true })
    .eq('professional_id', user!.id)
    .eq('archived', false)

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Hero section */}
      <div className="hero-section relative">
        <div className="gradient-blob-pink w-32 h-32 -top-10 -left-10" />
        <div className="gradient-blob-gold w-24 h-24 -bottom-8 -right-8" />
        <div className="relative">
          <h1 className="text-2xl font-bold mb-2">
            Welcome back, {professional?.name || 'Professional'}
          </h1>
          <p className="text-muted-foreground">
            Here&apos;s what&apos;s happening with your sessions
          </p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
              <Clock className="w-5 h-5 text-primary" />
            </div>
            <p className="text-sm text-muted-foreground">Total Sessions</p>
          </div>
          <p className="text-3xl font-bold">{totalSessions || 0}</p>
        </div>
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-lg bg-secondary/10 flex items-center justify-center">
              <Users className="w-5 h-5 text-secondary" />
            </div>
            <p className="text-sm text-muted-foreground">Clients</p>
          </div>
          <p className="text-3xl font-bold">{totalClients || 0}</p>
        </div>
        <div className="card p-6">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-10 h-10 rounded-lg bg-success/10 flex items-center justify-center">
              <CreditCard className="w-5 h-5 text-success" />
            </div>
            <p className="text-sm text-muted-foreground">Subscription</p>
          </div>
          <p className="text-3xl font-bold capitalize">
            {professional?.organization?.subscription_status || 'Free'}
          </p>
        </div>
      </div>

      {/* Recent Sessions */}
      <div className="card">
        <div className="p-6 border-b border-border">
          <div className="flex items-center justify-between">
            <h2 className="section-header">Recent Sessions</h2>
            <Link
              href="/sessions"
              className="text-sm text-primary hover:underline"
            >
              View all
            </Link>
          </div>
        </div>
        <div className="divide-y divide-border">
          {sessions && sessions.length > 0 ? (
            sessions.map((session) => (
              <Link
                key={session.id}
                href={`/sessions/${session.id}`}
                className="block p-4 hover:bg-accent/50 transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="avatar-sm">
                      {session.client?.name?.charAt(0).toUpperCase() || '?'}
                    </div>
                    <div>
                      <p className="font-medium">
                        {session.client?.name ||
                          session.title ||
                          `Session on ${new Date(session.created_at).toLocaleDateString()}`}
                      </p>
                      <p className="text-sm text-muted-foreground">
                        {session.client?.name || 'No client'} &bull;{' '}
                        {Math.floor(session.duration_seconds / 60)} min
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {session.recap && (
                      <span className={`status-pill ${getRecapStatusClass(session.recap.status)}`}>
                        {getRecapStatusLabel(session.recap.status)}
                      </span>
                    )}
                    <span className={`status-pill ${getSessionStatusClass(session.session_status)}`}>
                      {session.session_status}
                    </span>
                  </div>
                </div>
              </Link>
            ))
          ) : (
            <div className="p-8 text-center text-muted-foreground">
              No sessions yet. Record your first session using the iOS app.
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
