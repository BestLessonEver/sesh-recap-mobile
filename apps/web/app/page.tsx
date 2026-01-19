import Link from 'next/link'
import { Mic, Sparkles, Mail } from 'lucide-react'

export default function Home() {
  return (
    <main className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <header className="border-b border-border">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <span className="text-xl font-bold brand-gradient-text">Sesh.Rec</span>
          <div className="flex items-center gap-4">
            <Link
              href="/auth/login"
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
            >
              Sign In
            </Link>
            <Link href="/auth/signup" className="btn btn-primary">
              Get Started
            </Link>
          </div>
        </div>
      </header>

      {/* Hero */}
      <div className="flex-1 flex items-center justify-center px-4 py-16">
        <div className="max-w-2xl text-center relative">
          {/* Gradient blobs */}
          <div className="gradient-blob-pink w-64 h-64 -top-20 -left-32" />
          <div className="gradient-blob-gold w-48 h-48 -bottom-16 -right-24" />

          <div className="relative">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-full mb-6">
              <div className="w-full h-full rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center">
                <Mic className="w-10 h-10 text-white" />
              </div>
            </div>

            <h1 className="text-4xl md:text-5xl font-bold mb-4">
              <span className="brand-gradient-text">Session Recaps</span>
              <br />
              <span className="text-foreground">Made Simple</span>
            </h1>

            <p className="text-lg text-muted-foreground mb-8 max-w-lg mx-auto">
              Record sessions, generate AI recaps, and send professional summaries to attendees with one tap.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link href="/auth/signup" className="btn btn-primary text-base px-8 py-3">
                Start Free Trial
              </Link>
              <Link
                href="/auth/login"
                className="btn btn-secondary text-base px-8 py-3"
              >
                Sign In
              </Link>
            </div>

            <p className="text-sm text-muted-foreground mt-4">
              7-day free trial. No credit card required.
            </p>
          </div>
        </div>
      </div>

      {/* Features */}
      <div className="border-t border-border py-16">
        <div className="max-w-4xl mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="card p-6 text-center">
              <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mx-auto mb-4">
                <Mic className="w-6 h-6 text-primary" />
              </div>
              <h3 className="font-semibold mb-2">Record Sessions</h3>
              <p className="text-sm text-muted-foreground">
                Capture your sessions with one tap using our iOS app.
              </p>
            </div>
            <div className="card p-6 text-center">
              <div className="w-12 h-12 rounded-xl bg-secondary/10 flex items-center justify-center mx-auto mb-4">
                <Sparkles className="w-6 h-6 text-secondary" />
              </div>
              <h3 className="font-semibold mb-2">AI Recaps</h3>
              <p className="text-sm text-muted-foreground">
                Get instant AI-generated summaries of your sessions.
              </p>
            </div>
            <div className="card p-6 text-center">
              <div className="w-12 h-12 rounded-xl bg-success/10 flex items-center justify-center mx-auto mb-4">
                <Mail className="w-6 h-6 text-success" />
              </div>
              <h3 className="font-semibold mb-2">Email Summaries</h3>
              <p className="text-sm text-muted-foreground">
                Send professional recaps to attendees with one click.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t border-border py-8">
        <div className="max-w-6xl mx-auto px-4 text-center text-sm text-muted-foreground">
          <span className="brand-gradient-text font-semibold">Sesh.Rec</span>
          {' '}&bull; Session recaps made simple
        </div>
      </footer>
    </main>
  )
}
