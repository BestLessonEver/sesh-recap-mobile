import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import type { SessionWithRelations } from '@/types/database'
import { getSessionStatusClass, getRecapStatusClass, getRecapStatusLabel } from '@/lib/utils'

export default async function SessionsPage() {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { data: sessions } = await supabase
    .from('sessions')
    .select('*, client:attendants!attendant_id(*), recap:recaps(*)')
    .eq('professional_id', user!.id)
    .order('created_at', { ascending: false }) as { data: SessionWithRelations[] | null }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Sessions</h1>
          <p className="text-muted-foreground">
            {sessions?.length || 0} total sessions
          </p>
        </div>
      </div>

      {sessions && sessions.length > 0 ? (
        <div className="space-y-3">
          {sessions.map((session) => (
            <Link
              key={session.id}
              href={`/sessions/${session.id}`}
              className="list-item block"
            >
              <div className="flex items-start justify-between w-full">
                <div className="flex items-center gap-4">
                  <div className="avatar">
                    {session.client?.name?.charAt(0).toUpperCase() || '?'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium">
                      {session.client?.name ||
                        session.title ||
                        new Date(session.created_at).toLocaleDateString()}
                    </h3>
                    <p className="text-sm text-muted-foreground mt-0.5">
                      {session.client?.name || 'No client'} &bull;{' '}
                      {Math.floor(session.duration_seconds / 60)} min &bull;{' '}
                      {new Date(session.created_at).toLocaleString()}
                    </p>
                    {session.transcript_text && (
                      <p className="text-sm text-muted-foreground mt-2 line-clamp-2">
                        {session.transcript_text}
                      </p>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2 ml-4 shrink-0">
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
          ))}
        </div>
      ) : (
        <div className="card p-12 text-center">
          <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">🎙️</span>
          </div>
          <h3 className="font-semibold mb-2">No sessions yet</h3>
          <p className="text-muted-foreground">
            Record your first session using the iOS app to get started.
          </p>
        </div>
      )}
    </div>
  )
}
