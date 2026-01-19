# Sesh Recap

iOS-first app for session-based professionals to record sessions, generate AI recaps, and send summary emails to attendees.

## Target Users

- Tutors & educators (academic, language, driving, etc.)
- Coaches & trainers (life, fitness, sports, business)
- Therapists & consultants
- Any professional with 1:1 or group sessions

## Architecture

```
┌─────────────────┐                          ┌─────────────────────────────┐
│   iOS App       │────────────────────────▶│        SUPABASE             │
│   (Swift)       │                          │  ┌─────────────────────┐   │
└─────────────────┘                          │  │  Auth (Apple SSO)   │   │
        │                                    │  ├─────────────────────┤   │
        ├──▶ RevenueCat (subscriptions)      │  │  PostgreSQL + Pool  │   │
        │                                    │  ├─────────────────────┤   │
┌─────────────────┐                          │  │  Storage (CDN)      │   │
│   Web App       │────────────────────────▶│  ├─────────────────────┤   │
│   (Next.js)     │                          │  │  Edge Functions     │   │
└─────────────────┘                          │  └─────────────────────┘   │
                                             └─────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| iOS App | Swift/SwiftUI |
| Web App | Next.js |
| Backend | Supabase Edge Functions |
| Database | Supabase PostgreSQL |
| Auth | Supabase Auth (Apple Sign-In) |
| Storage | Supabase Storage |
| Transcription | AssemblyAI |
| AI Recaps | OpenAI GPT-4o |
| Email | Postmark |
| iOS Billing | RevenueCat |
| Web Billing | Stripe |

## Project Structure

```
sesh-recap-mobile/
├── apps/
│   ├── ios/                    # iOS Swift project
│   └── web/                    # Next.js web app
├── packages/
│   └── api/                    # Supabase Edge Functions
└── .github/
    └── workflows/              # CI/CD
```

## Getting Started

### Prerequisites

- Node.js 20+
- pnpm 9+
- Xcode 15+ (for iOS development)
- Supabase CLI

### Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   pnpm install
   ```

3. Set up environment variables (see each app's README)

4. Start development:
   ```bash
   pnpm dev
   ```

## Environment Variables

### Supabase Edge Functions

```
OPENAI_API_KEY=sk-...
ASSEMBLYAI_API_KEY=...
POSTMARK_SERVER_TOKEN=...
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...
REVENUECAT_API_KEY=...
```

### Web App (.env.local)

```
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

## Pricing

- $9.99/month per organization (includes 1 professional)
- $2.99/month per additional professional
- 7-day free trial
