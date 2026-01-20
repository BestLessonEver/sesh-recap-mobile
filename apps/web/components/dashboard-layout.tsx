'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import {
  Home,
  Mic,
  Clock,
  Users,
  Settings,
  LogOut,
} from 'lucide-react'
import { cn, getInitials } from '@/lib/utils'
import { ThemeToggle } from '@/components/theme-toggle'
import { createClient } from '@/lib/supabase/client'

interface Professional {
  id: string
  name: string
  email: string
  role: string
}

interface DashboardLayoutProps {
  children: React.ReactNode
  professional: Professional | null
}

// Desktop/sidebar navigation
const sidebarNavigation = [
  { name: 'Home', href: '/dashboard', icon: Home },
  { name: 'Sessions', href: '/sessions', icon: Clock },
  { name: 'Attendants', href: '/attendants', icon: Users },
  { name: 'Settings', href: '/settings', icon: Settings },
]

// Mobile bottom nav - 4 items with record button in center
const mobileNavigation = [
  { name: 'Home', href: '/dashboard', icon: Home },
  { name: 'Sessions', href: '/sessions', icon: Clock },
  // Record button goes in the middle (handled separately)
  { name: 'Attendants', href: '/attendants', icon: Users },
  { name: 'Settings', href: '/settings', icon: Settings },
]

export function DashboardLayout({ children, professional }: DashboardLayoutProps) {
  const pathname = usePathname()
  const router = useRouter()

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/')
    router.refresh()
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Mobile header */}
      <header className="sticky top-0 z-40 md:hidden bg-background border-b border-border">
        <div className="flex h-14 items-center justify-between px-4">
          <span className="text-lg font-bold brand-gradient-text">Sesh.Rec</span>
          <div className="flex items-center gap-1">
            <div className="avatar">
              {professional?.name ? getInitials(professional.name) : 'U'}
            </div>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Desktop sidebar */}
        <aside className="hidden md:flex w-60 shrink-0 flex-col border-r border-border bg-background min-h-screen">
          <div className="flex h-14 items-center px-4">
            <span className="text-lg font-bold brand-gradient-text">Sesh.Rec</span>
          </div>

          <nav className="flex-1 py-4 px-3 space-y-1">
            {sidebarNavigation.map((item) => {
              const isActive = pathname === item.href
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  className={cn('nav-item', isActive && 'active')}
                >
                  <item.icon className="w-5 h-5" />
                  <span>{item.name}</span>
                </Link>
              )
            })}

            <div className="h-px bg-border my-3" />
            <ThemeToggle showLabel />
          </nav>

          {/* User profile section */}
          <div className="p-4 border-t border-border">
            <div className="flex items-center gap-3">
              <div className="avatar">
                {professional?.name ? getInitials(professional.name) : 'U'}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium truncate">
                  {professional?.name || 'User'}
                </p>
                <p className="text-xs text-muted-foreground truncate">
                  {professional?.role || 'Professional'}
                </p>
              </div>
              <button
                onClick={handleSignOut}
                className="p-2 text-muted-foreground hover:text-foreground transition-colors"
                title="Sign out"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        </aside>

        {/* Main content */}
        <main className="flex-1 min-h-screen pb-24 md:pb-0">
          <div className="max-w-4xl mx-auto p-4 md:p-8">
            {children}
          </div>
        </main>
      </div>

      {/* Mobile bottom navigation with centered record button */}
      <nav className="mobile-nav md:hidden">
        <div className="flex h-16 items-center justify-around relative">
          {/* Left side nav items */}
          {mobileNavigation.slice(0, 2).map((item) => {
            const isActive = pathname === item.href
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn('mobile-nav-item', isActive && 'active')}
              >
                <item.icon className="w-5 h-5" />
                <span className="text-[10px] font-medium">{item.name}</span>
              </Link>
            )
          })}

          {/* Center record button - elevated */}
          <div className="relative -mt-6">
            <Link
              href="/sessions/new"
              className="record-btn w-14 h-14 shadow-lg shadow-destructive/30"
            >
              <Mic className="w-6 h-6 text-white" />
            </Link>
          </div>

          {/* Right side nav items */}
          {mobileNavigation.slice(2).map((item) => {
            const isActive = pathname === item.href
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn('mobile-nav-item', isActive && 'active')}
              >
                <item.icon className="w-5 h-5" />
                <span className="text-[10px] font-medium">{item.name}</span>
              </Link>
            )
          })}
        </div>
      </nav>
    </div>
  )
}
