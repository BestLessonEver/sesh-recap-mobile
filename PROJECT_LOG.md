# Project Log: Sesh Recap

## Overview
iOS-first app for session-based professionals (tutors, coaches, therapists) to record sessions, generate AI recaps using transcription and GPT, and send summary emails to attendees. Features native iOS recording, Supabase backend, RevenueCat/Stripe billing, and a Next.js web dashboard.

## Tech Stack
- **iOS**: Swift/SwiftUI, Supabase Swift SDK, RevenueCat
- **Web**: Next.js 14 (App Router), TypeScript, Tailwind CSS
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **AI**: AssemblyAI (transcription), OpenAI GPT-4o (recap generation)
- **Email**: Postmark
- **Billing**: RevenueCat (iOS), Stripe (web)

## Key Decisions
- **2025-01-19**: Restructured web app pages into `(dashboard)` route group — Shared layout with sidebar/mobile nav, auth check happens once in layout
- **2025-01-18**: Used Supabase instead of custom backend — All-in-one solution with auto-scaling, native iOS SDK, built-in Apple Sign-In support
- **2025-01-18**: Chose "attendant" terminology over "student" — More generic for coaches, therapists, consultants beyond just tutoring
- **2025-01-18**: Private storage bucket for audio files — Security; access via signed URLs only

## Mistakes & Lessons
- **2026-01-19**: xcconfig files with URLs fail silently - `//` in URLs is treated as comment → Hardcode credentials directly in `AppConfig.swift` for development. For production, use a different approach (e.g., plist without xcconfig, or CI injection).
- **2026-01-19**: xcodegen `configFiles:` doesn't reliably pass values to Info.plist → Even with proper xcconfig setup, `Bundle.main.object(forInfoDictionaryKey:)` returns nil. Hardcode values in Swift code as workaround.
- **2026-01-19**: Supabase Swift SDK v2 has type naming conflicts → Rename wrapper class from `SupabaseClient` to `Database` to avoid conflict with SDK's `SupabaseClient`. Use `Auth.Session` typealias for auth sessions to avoid conflict with our `Session` model.
- **2026-01-19**: SwiftUI `@Environment` conflicts with custom `Environment` enum → Rename config enum to `AppConfig` to avoid shadowing SwiftUI's property wrapper.
- **2026-01-19**: Supabase Swift SDK requires Encodable types for insert/update → Cannot use `[String: Any]` dictionaries. Create dedicated `InsertXxxRequest` structs that are Codable.
- **2026-01-19**: @MainActor isolated classes require `await` for property access from async contexts → Add `await` when accessing `Database.shared.currentUserId` from non-MainActor code.
- **2025-01-19**: New web app created with generic design instead of porting existing lesson-bot design → Always port CSS/tailwind config from `/users/bc/lesson-bot` when rebuilding the web app
- **2025-01-19**: iOS project setup requires xcodegen → Run `brew install xcodegen` then `cd apps/ios && xcodegen generate` to regenerate the .xcodeproj from project.yml
- **2025-01-18**: "database error saving new user" on signup → Trigger function `handle_new_user()` needs `SECURITY DEFINER SET search_path = public` to bypass RLS when inserting into professionals table
- **2025-01-18**: Browser automation typing into Monaco editor caused SQL syntax errors → Use JavaScript `editor.setValue()` to set content directly in Supabase SQL Editor

## Current State
**Working:**
- Supabase project created and configured (Project ID: `lkwxiocbnfpqglxqmsbj`)
- Database schema with 8 tables + RLS policies
- Apple Sign-In enabled (bundle ID: `com.seshrecap.app`)
- Storage bucket `audio-files` created
- Edge Functions deployed (transcribe, generate-recap, send-recap, stripe-webhook, revenuecat-webhook)
- Web app authentication working (email/password signup)
- Web app dark theme design with brand colors (hot pink/gold gradients)
- Dashboard layout with sidebar (desktop) and bottom nav (mobile)
- Theme toggle (dark/light mode with localStorage persistence)
- iOS Xcode project builds successfully on simulator
- iOS Swift packages configured (supabase-swift v2, RevenueCat)

**In Progress:**
- iOS app runtime testing in simulator
- Stripe/RevenueCat integration pending

**Blocked:**
- Apple Developer account needed for Sign in with Apple (web and iOS)
- Apple Developer account needed for TestFlight/App Store

## Supabase Credentials
- **Project URL**: `https://lkwxiocbnfpqglxqmsbj.supabase.co`
- **Project ID**: `lkwxiocbnfpqglxqmsbj`
- **Config Files**:
  - iOS: Hardcoded in `apps/ios/SeshRecap/Config/Environment.swift` (xcconfig approach failed)
  - Web: `apps/web/.env.local`

## Database Tables
- `organizations` - Companies/practices/studios
- `professionals` - Users who record sessions (linked to auth.users)
- `attendants` - People who attend sessions
- `sessions` - Recorded meetings with audio/transcripts
- `recaps` - AI-generated summaries
- `subscriptions` - Billing status
- `invitations` - Team member invites
- `device_tokens` - Push notification tokens

## Changelog
### 2026-01-19
- Fixed iOS Swift/Supabase SDK v2 compatibility issues (`a0b588a`)
- Renamed wrapper class from `SupabaseClient` to `Database` to avoid SDK naming conflict
- Renamed `Environment` enum to `AppConfig` to avoid SwiftUI `@Environment` conflict
- Added `AuthSession` typealias for `Auth.Session` to avoid `Session` model conflict
- Created Encodable request structs for all Supabase insert/update operations
- Added explicit `DismissAction` type annotations to `@Environment(\.dismiss)` properties
- Added `await` for @MainActor isolated `Database.shared` access
- Fixed Storage API calls to use new method signatures (`upload(_:data:options:)`)
- iOS app now builds successfully on iPhone 17 Pro Simulator
- Fixed runtime crash: xcconfig files don't work with URLs containing `//` (treated as comments)
- Hardcoded Supabase credentials directly in `AppConfig.swift` as workaround
- Added Info.plist keys for SUPABASE_URL, SUPABASE_ANON_KEY, REVENUECAT_API_KEY (for future xcconfig use)

### 2025-01-19
- Restored dark theme design from lesson-bot to web app
- Ported CSS design system (HSL variables, brand colors hot pink #FF69B4 / gold #FFD700)
- Created ThemeProvider, ThemeToggle, DashboardLayout components
- Restructured pages into `(dashboard)` route group with shared layout
- Updated landing page with gradient branding and feature cards
- Added mobile bottom navigation with centered record button
- Installed tailwindcss-animate, lucide-react, clsx, tailwind-merge
- Created iOS Xcode project using xcodegen (`91326de`)
- Added project.yml, Info.plist, entitlements, Assets.xcassets
- Configured Swift packages: supabase-swift, RevenueCat

### 2025-01-18
- Supabase project "Sesh Recap" created in "Best Lesson Ever!" organization
- Database schema migration run (8 tables, indexes, triggers)
- RLS policies enabled for multi-tenant isolation
- Apple Sign-In configured with bundle ID `com.seshrecap.app`
- Storage bucket `audio-files` created (private)
- Credentials saved to iOS xcconfig and web .env.local
- Edge Functions deployed with secrets (OpenAI, AssemblyAI, Postmark)
- Fixed `handle_new_user()` trigger with SECURITY DEFINER to bypass RLS
- Web app authentication tested and working
