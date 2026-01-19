import { NextRequest, NextResponse } from 'next/server'
import Stripe from 'stripe'
import { createClient } from '@supabase/supabase-js'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16',
})

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export async function POST(request: NextRequest) {
  const body = await request.text()
  const signature = request.headers.get('stripe-signature')

  if (!signature) {
    return NextResponse.json({ error: 'Missing signature' }, { status: 400 })
  }

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (err) {
    console.error('Webhook signature verification failed:', err)
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 })
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        const organizationId = session.metadata?.organization_id
        const subscriptionId = session.subscription as string

        if (!organizationId || !subscriptionId) break

        const subscription = await stripe.subscriptions.retrieve(subscriptionId)

        await supabase.from('subscriptions').upsert({
          organization_id: organizationId,
          status: 'active',
          provider: 'stripe',
          provider_subscription_id: subscriptionId,
          provider_customer_id: session.customer as string,
          quantity: subscription.items.data[0]?.quantity || 1,
          current_period_start: new Date(
            subscription.current_period_start * 1000
          ).toISOString(),
          current_period_end: new Date(
            subscription.current_period_end * 1000
          ).toISOString(),
        })

        await supabase
          .from('organizations')
          .update({ subscription_status: 'active' })
          .eq('id', organizationId)

        break
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription
        const { data: existingSub } = await supabase
          .from('subscriptions')
          .select('organization_id')
          .eq('provider_subscription_id', subscription.id)
          .single()

        if (!existingSub) break

        const status = mapStripeStatus(subscription.status)

        await supabase
          .from('subscriptions')
          .update({
            status,
            quantity: subscription.items.data[0]?.quantity || 1,
            current_period_start: new Date(
              subscription.current_period_start * 1000
            ).toISOString(),
            current_period_end: new Date(
              subscription.current_period_end * 1000
            ).toISOString(),
          })
          .eq('provider_subscription_id', subscription.id)

        await supabase
          .from('organizations')
          .update({ subscription_status: status })
          .eq('id', existingSub.organization_id)

        break
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription

        const { data: existingSub } = await supabase
          .from('subscriptions')
          .select('organization_id')
          .eq('provider_subscription_id', subscription.id)
          .single()

        if (!existingSub) break

        await supabase
          .from('subscriptions')
          .update({ status: 'canceled' })
          .eq('provider_subscription_id', subscription.id)

        await supabase
          .from('organizations')
          .update({ subscription_status: 'canceled' })
          .eq('id', existingSub.organization_id)

        break
      }
    }

    return NextResponse.json({ received: true })
  } catch (err) {
    console.error('Webhook handler error:', err)
    return NextResponse.json(
      { error: 'Webhook handler failed' },
      { status: 500 }
    )
  }
}

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
    default:
      return 'expired'
  }
}
