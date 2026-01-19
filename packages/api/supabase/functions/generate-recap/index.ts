import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { handleCors } from '../_shared/cors.ts'
import { createSupabaseAdmin, createSupabaseClient } from '../_shared/supabase.ts'
import { json, error, unauthorized, notFound, serverError } from '../_shared/response.ts'

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')

interface GenerateRecapRequest {
  sessionId: string
}

const DEFAULT_PROMPT = `You are an assistant that creates professional session recap emails.
Based on the session transcript provided, generate a concise and helpful summary email.

The email should:
- Start with a brief overview of what was covered
- Include key points, topics, or skills discussed
- Note any action items, homework, or things to practice
- End with encouragement and what to focus on next

Keep the tone professional but warm. The summary should be 2-4 paragraphs.`

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

    const { sessionId }: GenerateRecapRequest = await req.json()

    if (!sessionId) {
      return error('sessionId is required')
    }

    const { data: session, error: sessionError } = await supabase
      .from('sessions')
      .select(`
        *,
        attendant:attendants(name),
        professional:professionals(
          name,
          organization:organizations(recap_prompt)
        )
      `)
      .eq('id', sessionId)
      .single()

    if (sessionError || !session) {
      return notFound('Session not found')
    }

    if (!session.transcript_text) {
      return error('Session has no transcript. Please transcribe first.')
    }

    const customPrompt = session.professional?.organization?.recap_prompt
    const systemPrompt = customPrompt || DEFAULT_PROMPT

    const attendantName = session.attendant?.name || 'the attendant'
    const professionalName = session.professional?.name || 'the professional'

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: systemPrompt },
          {
            role: 'user',
            content: `Session with ${attendantName}, led by ${professionalName}.

Session title: ${session.title || 'Untitled Session'}

Transcript:
${session.transcript_text}

Please generate a recap email for this session.`,
          },
        ],
        temperature: 0.7,
        max_tokens: 1000,
      }),
    })

    if (!openaiResponse.ok) {
      console.error('OpenAI error:', await openaiResponse.text())
      return serverError('Failed to generate recap')
    }

    const openaiData = await openaiResponse.json()
    const recapText = openaiData.choices[0]?.message?.content

    if (!recapText) {
      return serverError('No recap generated')
    }

    const subject = `Session Recap: ${session.title || new Date(session.created_at).toLocaleDateString()}`

    const { data: existingRecap } = await supabase
      .from('recaps')
      .select('id')
      .eq('session_id', sessionId)
      .single()

    let recap
    if (existingRecap) {
      const { data, error: updateError } = await supabaseAdmin
        .from('recaps')
        .update({
          subject,
          body_text: recapText,
          status: 'draft',
        })
        .eq('id', existingRecap.id)
        .select()
        .single()

      if (updateError) throw updateError
      recap = data
    } else {
      const { data, error: insertError } = await supabaseAdmin
        .from('recaps')
        .insert({
          session_id: sessionId,
          organization_id: session.organization_id,
          subject,
          body_text: recapText,
          status: 'draft',
        })
        .select()
        .single()

      if (insertError) throw insertError
      recap = data
    }

    return json({
      success: true,
      recap,
    })
  } catch (err) {
    console.error('Generate recap error:', err)
    return serverError('Internal server error')
  }
})
