import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

export function getSessionStatusClass(status: string): string {
  switch (status) {
    case 'ready':
      return 'ready'
    case 'error':
      return 'error'
    default:
      return 'pending'
  }
}

export function getRecapStatusClass(status: string): string {
  return status === 'sent' ? 'sent' : 'draft'
}

export function getRecapStatusLabel(status: string): string {
  return status === 'sent' ? 'Sent' : 'Draft'
}
