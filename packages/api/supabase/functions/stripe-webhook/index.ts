import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'
import { json, error, serverError } from '../_shared/response.ts'
import Stripe from 'https://esm.sh/stripe@14.10.0?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')!

const stripe = new Stripe(STRIPE_SECRET_KEY, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  if (req.method !== 'POST') {
    return error('Method not allowed', 405)
  }

  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return error('Missing stripe-signature header', 400)
  }

  const body = await req.text()

  let event: Stripe.Event
  try {
    event = await stripe.webhooks.constructEventAsync(body, signature, STRIPE_WEBHOOK_SECRET)
  } catch (err) {
    console.error('Webhook signature verification failed:', err)
    return error('Invalid signature', 400)
  }

  const supabaseAdmin = createSupabaseAdmin()

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        const organizationId = session.metadata?.organization_id
        const subscriptionId = session.subscription as string

        if (!organizationId || !subscriptionId) break

        const subscription = await stripe.subscriptions.retrieve(subscriptionId)

        await supabaseAdmin.from('subscriptions').upsert({
          organization_id: organizationId,
          status: 'active',
          provider: 'stripe',
          provider_subscription_id: subscriptionId,
          provider_customer_id: session.customer as string,
          quantity: subscription.items.data[0]?.quantity || 1,
          current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
          current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
        })

        await supabaseAdmin
          .from('organizations')
          .update({ subscription_status: 'active' })
          .eq('id', organizationId)

        break
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription
        const { data: existingSub } = await supabaseAdmin
          .from('subscriptions')
          .select('organization_id')
          .eq('provider_subscription_id', subscription.id)
          .single()

        if (!existingSub) break

        const status = mapStripeStatus(subscription.status)

        await supabaseAdmin
          .from('subscriptions')
          .update({
            status,
            quantity: subscription.items.data[0]?.quantity || 1,
            current_period_start: new Date(subscription.current_period_start * 1000).toISOString(),
            current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
          })
          .eq('provider_subscription_id', subscription.id)

        await supabaseAdmin
          .from('organizations')
          .update({ subscription_status: status })
          .eq('id', existingSub.organization_id)

        break
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription

        const { data: existingSub } = await supabaseAdmin
          .from('subscriptions')
          .select('organization_id')
          .eq('provider_subscription_id', subscription.id)
          .single()

        if (!existingSub) break

        await supabaseAdmin
          .from('subscriptions')
          .update({ status: 'canceled' })
          .eq('provider_subscription_id', subscription.id)

        await supabaseAdmin
          .from('organizations')
          .update({ subscription_status: 'canceled' })
          .eq('id', existingSub.organization_id)

        break
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice
        const subscriptionId = invoice.subscription as string

        if (!subscriptionId) break

        const { data: existingSub } = await supabaseAdmin
          .from('subscriptions')
          .select('organization_id')
          .eq('provider_subscription_id', subscriptionId)
          .single()

        if (!existingSub) break

        await supabaseAdmin
          .from('subscriptions')
          .update({ status: 'past_due' })
          .eq('provider_subscription_id', subscriptionId)

        await supabaseAdmin
          .from('organizations')
          .update({ subscription_status: 'past_due' })
          .eq('id', existingSub.organization_id)

        break
      }
    }

    return json({ received: true })
  } catch (err) {
    console.error('Webhook handler error:', err)
    return serverError('Webhook handler failed')
  }
})

function mapStripeStatus(stripeStatus: Stripe.Subscription.Status): string {
  switch (stripeStatus) {
    case 'active':
      return 'active'
    case 'trialing':
      return 'trialing'
    case 'past_due':
      return 'past_due'
    case 'canceled':
    case 'unpaid':
      return 'canceled'
    case 'incomplete':
    case 'incomplete_expired':
    case 'paused':
      return 'expired'
    default:
      return 'expired'
  }
}
