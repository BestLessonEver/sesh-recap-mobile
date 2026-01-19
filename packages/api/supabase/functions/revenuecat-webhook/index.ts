import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { json, error, serverError } from '../_shared/response.ts'

const REVENUECAT_WEBHOOK_SECRET = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')

interface RevenueCatEvent {
  api_version: string
  event: {
    type: string
    id: string
    app_user_id: string
    product_id: string
    entitlement_ids: string[]
    period_type: string
    purchased_at_ms: number
    expiration_at_ms: number
    store: string
    environment: string
    is_trial_conversion: boolean
    original_app_user_id: string
    aliases: string[]
  }
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return error('Method not allowed', 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (REVENUECAT_WEBHOOK_SECRET && authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET}`) {
    return error('Unauthorized', 401)
  }

  const body: RevenueCatEvent = await req.json()
  const { event } = body
  const supabaseAdmin = createSupabaseAdmin()

  try {
    const userId = event.app_user_id

    const { data: professional } = await supabaseAdmin
      .from('professionals')
      .select('organization_id')
      .eq('id', userId)
      .single()

    if (!professional?.organization_id) {
      console.log('No organization found for user:', userId)
      return json({ received: true })
    }

    const organizationId = professional.organization_id

    switch (event.type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'PRODUCT_CHANGE': {
        await supabaseAdmin.from('subscriptions').upsert(
          {
            organization_id: organizationId,
            status: 'active',
            provider: 'app_store',
            provider_subscription_id: event.id,
            provider_customer_id: event.original_app_user_id,
            quantity: 1,
            current_period_start: new Date(event.purchased_at_ms).toISOString(),
            current_period_end: new Date(event.expiration_at_ms).toISOString(),
          },
          {
            onConflict: 'organization_id',
          }
        )

        await supabaseAdmin
          .from('organizations')
          .update({ subscription_status: 'active' })
          .eq('id', organizationId)

        break
      }

      case 'CANCELLATION':
      case 'EXPIRATION': {
        await supabaseAdmin
          .from('subscriptions')
          .update({
            status: event.type === 'CANCELLATION' ? 'canceled' : 'expired',
            current_period_end: new Date(event.expiration_at_ms).toISOString(),
          })
          .eq('organization_id', organizationId)
          .eq('provider', 'app_store')

        await supabaseAdmin
          .from('organizations')
          .update({
            subscription_status: event.type === 'CANCELLATION' ? 'canceled' : 'expired',
          })
          .eq('id', organizationId)

        break
      }

      case 'BILLING_ISSUE': {
        await supabaseAdmin
          .from('subscriptions')
          .update({ status: 'past_due' })
          .eq('organization_id', organizationId)
          .eq('provider', 'app_store')

        await supabaseAdmin
          .from('organizations')
          .update({ subscription_status: 'past_due' })
          .eq('id', organizationId)

        break
      }

      case 'SUBSCRIBER_ALIAS': {
        console.log('Subscriber alias event:', event.aliases)
        break
      }

      default:
        console.log('Unhandled RevenueCat event type:', event.type)
    }

    return json({ received: true })
  } catch (err) {
    console.error('RevenueCat webhook error:', err)
    return serverError('Webhook handler failed')
  }
})
