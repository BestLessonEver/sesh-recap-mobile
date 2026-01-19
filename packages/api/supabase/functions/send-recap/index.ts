import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { handleCors } from '../_shared/cors.ts'
import { createSupabaseAdmin, createSupabaseClient } from '../_shared/supabase.ts'
import { json, error, unauthorized, notFound, serverError } from '../_shared/response.ts'

const POSTMARK_SERVER_TOKEN = Deno.env.get('POSTMARK_SERVER_TOKEN')
const FROM_EMAIL = Deno.env.get('FROM_EMAIL') || 'hello@seshrecap.com'

interface SendRecapRequest {
  sessionId: string
}

serve(async (req) => {
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  try {
    const supabase = createSupabaseClient(req)
    const supabaseAdmin = createSupabaseAdmin()

    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) return unauthorized()

    const { sessionId }: SendRecapRequest = await req.json()

    if (!sessionId) {
      return error('sessionId is required')
    }

    const { data: session, error: sessionError } = await supabase
      .from('sessions')
      .select(`
        *,
        attendant:attendants(*),
        recap:recaps(*)
      `)
      .eq('id', sessionId)
      .single()

    if (sessionError || !session) {
      return notFound('Session not found')
    }

    if (!session.recap || session.recap.length === 0) {
      return error('No recap found. Please generate a recap first.')
    }

    const recap = Array.isArray(session.recap) ? session.recap[0] : session.recap

    if (!session.attendant) {
      return error('No attendant associated with this session')
    }

    const recipientEmails: string[] = []

    if (session.attendant.is_self_contact && session.attendant.email) {
      recipientEmails.push(session.attendant.email)
    }

    if (session.attendant.contact_emails?.length > 0) {
      recipientEmails.push(...session.attendant.contact_emails)
    }

    if (recipientEmails.length === 0) {
      return error('No email addresses found for attendant')
    }

    const { data: professional } = await supabase
      .from('professionals')
      .select('name, email')
      .eq('id', user.id)
      .single()

    const fromName = professional?.name || 'Sesh Recap'

    const emailPromises = recipientEmails.map(async (toEmail) => {
      const response = await fetch('https://api.postmarkapp.com/email', {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          'X-Postmark-Server-Token': POSTMARK_SERVER_TOKEN!,
        },
        body: JSON.stringify({
          From: `${fromName} <${FROM_EMAIL}>`,
          To: toEmail,
          Subject: recap.subject,
          TextBody: recap.body_text,
          ReplyTo: professional?.email || FROM_EMAIL,
          MessageStream: 'outbound',
        }),
      })

      if (!response.ok) {
        const errorText = await response.text()
        console.error(`Failed to send to ${toEmail}:`, errorText)
        throw new Error(`Failed to send email to ${toEmail}`)
      }

      return response.json()
    })

    try {
      await Promise.all(emailPromises)
    } catch (emailError) {
      await supabaseAdmin
        .from('recaps')
        .update({ status: 'failed' })
        .eq('id', recap.id)

      throw emailError
    }

    await supabaseAdmin
      .from('recaps')
      .update({
        status: 'sent',
        sent_at: new Date().toISOString(),
      })
      .eq('id', recap.id)

    return json({
      success: true,
      sentTo: recipientEmails,
    })
  } catch (err) {
    console.error('Send recap error:', err)
    return serverError('Failed to send recap email')
  }
})
