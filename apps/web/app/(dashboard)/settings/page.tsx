import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { SignOutButton } from './signout-button'
import type { Tables } from '@/types/database'

type Professional = Tables<'professionals'> & {
  organization: Tables<'organizations'> | null
}

type Subscription = Tables<'subscriptions'>

export default async function SettingsPage() {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { data: professional } = await supabase
    .from('professionals')
    .select('*, organization:organizations(*)')
    .eq('id', user!.id)
    .single() as { data: Professional | null }

  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('*')
    .eq('organization_id', professional?.organization_id || '')
    .single() as { data: Subscription | null }

  return (
    <div className="space-y-6 animate-fade-in">
      <div>
        <h1 className="text-2xl font-bold">Settings</h1>
        <p className="text-muted-foreground">Manage your account and preferences</p>
      </div>

      {/* Profile Section */}
      <section className="card p-6">
        <h3 className="section-header mb-4">Profile</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm text-muted-foreground mb-1">
              Name
            </label>
            <p className="font-medium">{professional?.name}</p>
          </div>
          <div>
            <label className="block text-sm text-muted-foreground mb-1">
              Email
            </label>
            <p className="font-medium">{professional?.email}</p>
          </div>
        </div>
      </section>

      {/* Subscription Section */}
      <section className="card p-6">
        <h3 className="section-header mb-4">Subscription</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm text-muted-foreground mb-1">
              Current Plan
            </label>
            <p className="font-medium capitalize">
              {professional?.organization?.subscription_status || 'Free'}
            </p>
          </div>
          {subscription?.current_period_end && (
            <div>
              <label className="block text-sm text-muted-foreground mb-1">
                Renews
              </label>
              <p className="font-medium">
                {new Date(subscription.current_period_end).toLocaleDateString()}
              </p>
            </div>
          )}
          <Link href="/settings/billing" className="btn btn-primary">
            Manage Billing
          </Link>
        </div>
      </section>

      {/* Organization Section */}
      {professional?.organization && (
        <section className="card p-6">
          <h3 className="section-header mb-4">Organization</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm text-muted-foreground mb-1">
                Name
              </label>
              <p className="font-medium">{professional.organization.name}</p>
            </div>
            <div>
              <label className="block text-sm text-muted-foreground mb-1">
                Your Role
              </label>
              <p className="font-medium capitalize">{professional.role}</p>
            </div>
          </div>
        </section>
      )}

      {/* Sign Out */}
      <section className="card p-6">
        <h3 className="section-header mb-4">Account</h3>
        <SignOutButton />
      </section>
    </div>
  )
}
