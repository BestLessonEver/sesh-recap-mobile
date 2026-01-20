export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      organizations: {
        Row: {
          id: string
          name: string
          recap_prompt: string | null
          subscription_status: string
          max_professionals: number
          trial_ends_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          name: string
          recap_prompt?: string | null
          subscription_status?: string
          max_professionals?: number
          trial_ends_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          name?: string
          recap_prompt?: string | null
          subscription_status?: string
          max_professionals?: number
          trial_ends_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      professionals: {
        Row: {
          id: string
          organization_id: string | null
          name: string
          email: string
          role: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          organization_id?: string | null
          name: string
          email: string
          role?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          organization_id?: string | null
          name?: string
          email?: string
          role?: string
          created_at?: string
          updated_at?: string
        }
      }
      attendants: {
        Row: {
          id: string
          professional_id: string
          organization_id: string | null
          name: string
          email: string | null
          contact_emails: string[] | null
          contact_name: string | null
          is_self_contact: boolean
          tags: string[] | null
          notes: string | null
          archived: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          professional_id: string
          organization_id?: string | null
          name: string
          email?: string | null
          contact_emails?: string[] | null
          contact_name?: string | null
          is_self_contact?: boolean
          tags?: string[] | null
          notes?: string | null
          archived?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          professional_id?: string
          organization_id?: string | null
          name?: string
          email?: string | null
          contact_emails?: string[] | null
          contact_name?: string | null
          is_self_contact?: boolean
          tags?: string[] | null
          notes?: string | null
          archived?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      sessions: {
        Row: {
          id: string
          professional_id: string
          organization_id: string | null
          attendant_id: string | null
          title: string | null
          audio_url: string | null
          audio_chunks: string[] | null
          duration_seconds: number
          transcript_text: string | null
          session_status: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          professional_id: string
          organization_id?: string | null
          attendant_id?: string | null
          title?: string | null
          audio_url?: string | null
          audio_chunks?: string[] | null
          duration_seconds?: number
          transcript_text?: string | null
          session_status?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          professional_id?: string
          organization_id?: string | null
          attendant_id?: string | null
          title?: string | null
          audio_url?: string | null
          audio_chunks?: string[] | null
          duration_seconds?: number
          transcript_text?: string | null
          session_status?: string
          created_at?: string
          updated_at?: string
        }
      }
      recaps: {
        Row: {
          id: string
          session_id: string
          organization_id: string | null
          subject: string
          body_text: string
          status: string
          sent_at: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          session_id: string
          organization_id?: string | null
          subject: string
          body_text: string
          status?: string
          sent_at?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          session_id?: string
          organization_id?: string | null
          subject?: string
          body_text?: string
          status?: string
          sent_at?: string | null
          created_at?: string
          updated_at?: string
        }
      }
      subscriptions: {
        Row: {
          id: string
          organization_id: string
          status: string
          provider: string
          provider_subscription_id: string | null
          provider_customer_id: string | null
          quantity: number
          current_period_start: string | null
          current_period_end: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          organization_id: string
          status: string
          provider: string
          provider_subscription_id?: string | null
          provider_customer_id?: string | null
          quantity?: number
          current_period_start?: string | null
          current_period_end?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          organization_id?: string
          status?: string
          provider?: string
          provider_subscription_id?: string | null
          provider_customer_id?: string | null
          quantity?: number
          current_period_start?: string | null
          current_period_end?: string | null
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_user_organization_id: {
        Args: Record<PropertyKey, never>
        Returns: string | null
      }
      is_org_admin: {
        Args: Record<PropertyKey, never>
        Returns: boolean
      }
    }
    Enums: {
      [_ in never]: never
    }
  }
}

export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row']
export type InsertTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert']
export type UpdateTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update']

// Shared composite types used across the app
export type ProfessionalWithOrg = Tables<'professionals'> & {
  organization: Tables<'organizations'> | null
}

export type SessionWithRelations = Tables<'sessions'> & {
  attendant: Tables<'attendants'> | null
  recap: Tables<'recaps'> | null
}
