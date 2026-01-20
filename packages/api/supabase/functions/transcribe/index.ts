import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { handleCors } from '../_shared/cors.ts'
import { json, error, serverError } from '../_shared/response.ts'
import { createSupabaseAdmin } from '../_shared/supabase.ts'

const ASSEMBLYAI_API_KEY = Deno.env.get('ASSEMBLYAI_API_KEY')

serve(async (req) => {
  console.log('=== Transcribe function called ===')

  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  try {
    const authHeader = req.headers.get('Authorization')
    console.log('Auth header present:', !!authHeader)

    if (!authHeader) {
      return error('No authorization header', 401)
    }

    // Create admin client to verify the user
    const supabaseAdmin = createSupabaseAdmin()

    // Verify the JWT using admin client
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    console.log('getUser result - user:', user?.id, 'error:', userError)

    if (userError || !user) {
      return error('Invalid token', 401)
    }

    const { sessionId } = await req.json()
    console.log('sessionId:', sessionId)
    if (!sessionId) return error('sessionId is required')

    // Use admin client for all DB operations
    const { data: session, error: sessionError } = await supabaseAdmin
      .from('sessions')
      .select('*')
      .eq('id', sessionId)
      .single()

    console.log('Session query result:', session ? 'found' : 'not found', sessionError)

    if (sessionError || !session) {
      console.error('Session error:', sessionError)
      return error('Session not found', 404)
    }

    console.log('audio_url:', session.audio_url)
    console.log('audio_chunks:', session.audio_chunks)

    if (!session.audio_url && (!session.audio_chunks || session.audio_chunks.length === 0)) {
      return error('No audio file available for transcription')
    }

    await supabaseAdmin.from('sessions').update({ session_status: 'transcribing' }).eq('id', sessionId)

    const audioPath = session.audio_url || session.audio_chunks[0]
    console.log('audioPath:', audioPath)

    const { data: signedUrlData, error: signedUrlError } = await supabaseAdmin
      .storage.from('audio-files').createSignedUrl(audioPath, 3600)

    console.log('signedUrl created:', !!signedUrlData?.signedUrl, 'error:', signedUrlError)

    if (signedUrlError || !signedUrlData?.signedUrl) {
      console.error('Failed to create signed URL:', signedUrlError)
      return error('Failed to create audio URL')
    }

    console.log('Calling AssemblyAI...')
    console.log('ASSEMBLYAI_API_KEY present:', !!ASSEMBLYAI_API_KEY)

    const transcriptResponse = await fetch('https://api.assemblyai.com/v2/transcript', {
      method: 'POST',
      headers: { Authorization: ASSEMBLYAI_API_KEY!, 'Content-Type': 'application/json' },
      body: JSON.stringify({ audio_url: signedUrlData.signedUrl, language_detection: true }),
    })

    const transcriptData = await transcriptResponse.json()
    console.log('AssemblyAI response:', transcriptResponse.status, JSON.stringify(transcriptData))

    if (!transcriptResponse.ok) {
      await supabaseAdmin.from('sessions').update({ session_status: 'error' }).eq('id', sessionId)
      return serverError('Failed to start transcription: ' + JSON.stringify(transcriptData))
    }

    const { id: transcriptId } = transcriptData

    console.log('Starting polling for transcriptId:', transcriptId)

    let transcript = null
    for (let attempts = 0; attempts < 60; attempts++) {
      await new Promise((resolve) => setTimeout(resolve, 5000))
      const pollResponse = await fetch(`https://api.assemblyai.com/v2/transcript/${transcriptId}`, {
        headers: { Authorization: ASSEMBLYAI_API_KEY! },
      })
      const pollData = await pollResponse.json()

      console.log(`Poll attempt ${attempts + 1}: status=${pollData.status}`)

      if (pollData.status === 'completed') {
        transcript = pollData.text
        console.log('Transcription completed, length:', transcript?.length)
        break
      } else if (pollData.status === 'error') {
        console.error('AssemblyAI error:', pollData.error)

        // Handle common errors with user-friendly messages
        let userMessage = 'Transcription failed'
        let sessionStatus = 'error'

        const errorMsg = pollData.error?.toLowerCase() || ''
        if (errorMsg.includes('no spoken audio') || errorMsg.includes('no speech')) {
          userMessage = 'No speech detected in the recording. Please try again and speak clearly.'
          sessionStatus = 'no_speech'
        } else if (errorMsg.includes('too short') || errorMsg.includes('duration')) {
          userMessage = 'Recording is too short. Please record for at least a few seconds.'
          sessionStatus = 'too_short'
        } else if (errorMsg.includes('audio quality') || errorMsg.includes('muffled')) {
          userMessage = 'Audio quality is too low. Please try recording in a quieter environment.'
          sessionStatus = 'low_quality'
        }

        await supabaseAdmin.from('sessions').update({
          session_status: sessionStatus,
          error_message: userMessage
        }).eq('id', sessionId)

        return json({ success: false, error: userMessage, errorType: sessionStatus }, 400)
      }
    }

    if (!transcript) {
      await supabaseAdmin.from('sessions').update({
        session_status: 'error',
        error_message: 'Transcription timed out. Please try again.'
      }).eq('id', sessionId)
      return json({ success: false, error: 'Transcription timed out. Please try again.', errorType: 'timeout' }, 400)
    }

    await supabaseAdmin.from('sessions').update({ transcript_text: transcript, session_status: 'ready' }).eq('id', sessionId)

    return json({ success: true, sessionId, transcript })
  } catch (err) {
    console.error('Transcription error:', err)
    return serverError('Internal server error')
  }
})
