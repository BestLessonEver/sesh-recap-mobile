import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import type { Tables } from '@/types/database'

type Attendant = Tables<'attendants'>

export default async function AttendantsPage() {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { data: attendants } = await supabase
    .from('attendants')
    .select('*')
    .eq('professional_id', user!.id)
    .eq('archived', false)
    .order('name') as { data: Attendant[] | null }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Attendants</h1>
          <p className="text-muted-foreground">
            {attendants?.length || 0} attendants
          </p>
        </div>
      </div>

      {attendants && attendants.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {attendants.map((attendant) => (
            <Link
              key={attendant.id}
              href={`/attendants/${attendant.id}`}
              className="card card-hover p-6"
            >
              <div className="flex items-center gap-4">
                <div className="avatar">
                  {attendant.name.charAt(0).toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-medium truncate">{attendant.name}</h3>
                  <p className="text-sm text-muted-foreground truncate">
                    {attendant.is_self_contact
                      ? attendant.email
                      : attendant.contact_emails?.[0] || 'No email'}
                  </p>
                </div>
              </div>
              {attendant.tags && attendant.tags.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-4">
                  {attendant.tags.slice(0, 3).map((tag: string) => (
                    <span key={tag} className="tag">
                      {tag}
                    </span>
                  ))}
                  {attendant.tags.length > 3 && (
                    <span className="text-xs text-muted-foreground">
                      +{attendant.tags.length - 3} more
                    </span>
                  )}
                </div>
              )}
            </Link>
          ))}
        </div>
      ) : (
        <div className="card p-12 text-center">
          <div className="w-16 h-16 rounded-full bg-secondary/10 flex items-center justify-center mx-auto mb-4">
            <span className="text-3xl">👥</span>
          </div>
          <h3 className="font-semibold mb-2">No attendants yet</h3>
          <p className="text-muted-foreground">
            Add your first attendant using the iOS app.
          </p>
        </div>
      )}
    </div>
  )
}
