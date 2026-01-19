import { corsHeaders } from './cors.ts'

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}

export function error(message: string, status = 400): Response {
  return json({ error: message }, status)
}

export function unauthorized(message = 'Unauthorized'): Response {
  return error(message, 401)
}

export function notFound(message = 'Not found'): Response {
  return error(message, 404)
}

export function serverError(message = 'Internal server error'): Response {
  return error(message, 500)
}
