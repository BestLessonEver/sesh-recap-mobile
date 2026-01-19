import { NextResponse } from 'next/server'
import Stripe from 'stripe'
import { createClient } from '@/lib/supabase/server'
import type { Tables } from '@/types/database'

type Professional = Tables<'professionals'> & {
  organization: Tables<'organizations'> | null
}

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16',
})

export async function POST() {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { data: professional } = await supabase
    .from('professionals')
    .select('*, organization:organizations(*)')
    .eq('id', user.id)
    .single() as { data: Professional | null }

  if (!professional?.organization_id) {
    return NextResponse.json(
      { error: 'No organization found' },
      { status: 400 }
    )
  }

  // Check if customer already exists
  const { data: subscription } = await supabase
    .from('subscriptions')
    .select('provider_customer_id')
    .eq('organization_id', professional.organization_id)
    .eq('provider', 'stripe')
    .single() as { data: { provider_customer_id: string | null } | null }

  let customerId = subscription?.provider_customer_id

  // Create customer if doesn't exist
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: user.email,
      metadata: {
        organization_id: professional.organization_id,
        user_id: user.id,
      },
    })
    customerId = customer.id
  }

  // Create checkout session
  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [
      {
        price: process.env.STRIPE_PRICE_BASE!,
        quantity: 1,
      },
    ],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/settings?success=true`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/settings?canceled=true`,
    metadata: {
      organization_id: professional.organization_id,
    },
    subscription_data: {
      metadata: {
        organization_id: professional.organization_id,
      },
    },
    allow_promotion_codes: true,
  })

  return NextResponse.json({ url: session.url })
}
