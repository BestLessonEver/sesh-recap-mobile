import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { handleCors } from '../_shared/cors.ts'
import { createSupabaseAdmin, createSupabaseClient } from '../_shared/supabase.ts'
import { json, error, unauthorized, serverError } from '../_shared/response.ts'

const ASSEMBLYAI_API_KEY = Deno.env.get('ASSEMBLYAI_API_KEY')

interface TranscribeRequest {
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

    const { sessionId }: TranscribeRequest = await req.json()

    if (!sessionId) {
      return error('sessionId is required')
    }

    const { data: session, error: sessionError } = await supabase
      .from('sessions')
      .select('*')
      .eq('id', sessionId)
      .single()

    if (sessionError || !session) {
      return error('Session not found', 404)
    }

    if (!session.audio_url && (!session.audio_chunks || session.audio_chunks.length === 0)) {
      return error('No audio file available for transcription')
    }

    await supabaseAdmin
      .from('sessions')
      .update({ session_status: 'transcribing' })
      .eq('id', sessionId)

    const audioPath = session.audio_url || session.audio_chunks[0]

    // Create signed URL for AssemblyAI to access the audio
    const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin
      .storage
      .from('audio-files')
      .createSignedUrl(audioPath, 3600) // 1 hour expiry

    if (signedUrlError || !signedUrlData?.signedUrl) {
      console.error('Failed to create signed URL:', signedUrlError)
      return error('Failed to create audio URL')
    }

    const audioUrl = signedUrlData.signedUrl

    const transcriptResponse = await fetch('https://api.assemblyai.com/v2/transcript', {
      method: 'POST',
      headers: {
        Authorization: ASSEMBLYAI_API_KEY!,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        audio_url: audioUrl,
        language_detection: true,
      }),
    })

    if (!transcriptResponse.ok) {
      await supabaseAdmin
        .from('sessions')
        .update({ session_status: 'error' })
        .eq('id', sessionId)
      return serverError('Failed to start transcription')
    }

    const { id: transcriptId } = await transcriptResponse.json()

    let transcript = null
    let attempts = 0
    const maxAttempts = 60

    while (attempts < maxAttempts) {
      await new Promise((resolve) => setTimeout(resolve, 5000))

      const pollResponse = await fetch(`https://api.assemblyai.com/v2/transcript/${transcriptId}`, {
        headers: { Authorization: ASSEMBLYAI_API_KEY! },
      })

      const pollData = await pollResponse.json()

      if (pollData.status === 'completed') {
        transcript = pollData.text
        break
      } else if (pollData.status === 'error') {
        await supabaseAdmin
          .from('sessions')
          .update({ session_status: 'error' })
          .eq('id', sessionId)
        return serverError('Transcription failed')
      }

      attempts++
    }

    if (!transcript) {
      await supabaseAdmin
        .from('sessions')
        .update({ session_status: 'error' })
        .eq('id', sessionId)
      return serverError('Transcription timed out')
    }

    await supabaseAdmin
      .from('sessions')
      .update({
        transcript_text: transcript,
        session_status: 'ready',
      })
      .eq('id', sessionId)

    return json({
      success: true,
      sessionId,
      transcript,
    })
  } catch (err) {
    console.error('Transcription error:', err)
    return serverError('Internal server error')
  }
})
