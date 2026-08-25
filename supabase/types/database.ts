export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.15"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      attendance_records: {
        Row: {
          created_at: string
          date: string
          deleted_at: string | null
          id: string
          logged_by: string | null
          remarks: string | null
          site_id: string
          status: Database["public"]["Enums"]["attendance_status"]
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          date: string
          deleted_at?: string | null
          id?: string
          logged_by?: string | null
          remarks?: string | null
          site_id?: string
          status?: Database["public"]["Enums"]["attendance_status"]
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          date?: string
          deleted_at?: string | null
          id?: string
          logged_by?: string | null
          remarks?: string | null
          site_id?: string
          status?: Database["public"]["Enums"]["attendance_status"]
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "attendance_records_logged_by_fkey"
            columns: ["logged_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "attendance_records_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      cut_fill_records: {
        Row: {
          bcm_volume: number
          created_at: string
          daily_log_id: string | null
          deleted_at: string | null
          elevation_change: number | null
          id: string
          lcm_volume: number
          material_type: string | null
          measured_at: string
          measured_by: string | null
          site_id: string
          updated_at: string
          zone_id: string
        }
        Insert: {
          bcm_volume?: number
          created_at?: string
          daily_log_id?: string | null
          deleted_at?: string | null
          elevation_change?: number | null
          id?: string
          lcm_volume?: number
          material_type?: string | null
          measured_at?: string
          measured_by?: string | null
          site_id?: string
          updated_at?: string
          zone_id: string
        }
        Update: {
          bcm_volume?: number
          created_at?: string
          daily_log_id?: string | null
          deleted_at?: string | null
          elevation_change?: number | null
          id?: string
          lcm_volume?: number
          material_type?: string | null
          measured_at?: string
          measured_by?: string | null
          site_id?: string
          updated_at?: string
          zone_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "cut_fill_records_daily_log_id_fkey"
            columns: ["daily_log_id"]
            isOneToOne: false
            referencedRelation: "daily_logs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cut_fill_records_measured_by_fkey"
            columns: ["measured_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cut_fill_records_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      daily_logs: {
        Row: {
          approved_by: string | null
          created_at: string
          deleted_at: string | null
          foreman_id: string
          id: string
          log_date: string
          notes: string | null
          site_id: string
          status: Database["public"]["Enums"]["log_status"]
          summary: string | null
          updated_at: string
          weather: string | null
          zone_id: string | null
        }
        Insert: {
          approved_by?: string | null
          created_at?: string
          deleted_at?: string | null
          foreman_id: string
          id?: string
          log_date: string
          notes?: string | null
          site_id?: string
          status?: Database["public"]["Enums"]["log_status"]
          summary?: string | null
          updated_at?: string
          weather?: string | null
          zone_id?: string | null
        }
        Update: {
          approved_by?: string | null
          created_at?: string
          deleted_at?: string | null
          foreman_id?: string
          id?: string
          log_date?: string
          notes?: string | null
          site_id?: string
          status?: Database["public"]["Enums"]["log_status"]
          summary?: string | null
          updated_at?: string
          weather?: string | null
          zone_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_logs_approved_by_fkey"
            columns: ["approved_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_logs_foreman_id_fkey"
            columns: ["foreman_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_logs_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      equipment_checks: {
        Row: {
          check_time: string
          check_type: string
          checklist_data: Json
          created_at: string
          deleted_at: string | null
          equipment_type: Database["public"]["Enums"]["equipment_type"]
          foreman_id: string
          id: string
          is_operational: boolean
          remarks: string | null
          serial_number: string | null
          site_id: string
          updated_at: string
        }
        Insert: {
          check_time?: string
          check_type?: string
          checklist_data?: Json
          created_at?: string
          deleted_at?: string | null
          equipment_type: Database["public"]["Enums"]["equipment_type"]
          foreman_id: string
          id?: string
          is_operational?: boolean
          remarks?: string | null
          serial_number?: string | null
          site_id?: string
          updated_at?: string
        }
        Update: {
          check_time?: string
          check_type?: string
          checklist_data?: Json
          created_at?: string
          deleted_at?: string | null
          equipment_type?: Database["public"]["Enums"]["equipment_type"]
          foreman_id?: string
          id?: string
          is_operational?: boolean
          remarks?: string | null
          serial_number?: string | null
          site_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "equipment_checks_foreman_id_fkey"
            columns: ["foreman_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      geospatial_files: {
        Row: {
          acquisition_date: string | null
          created_at: string
          deleted_at: string | null
          drive_file_id: string
          drive_link: string | null
          drive_web_view_link: string | null
          file_name: string
          file_size_bytes: number | null
          file_type: string
          id: string
          metadata: Json
          mime_type: string | null
          notes: string | null
          site_id: string
          updated_at: string
          uploaded_by: string | null
          zone_id: string | null
        }
        Insert: {
          acquisition_date?: string | null
          created_at?: string
          deleted_at?: string | null
          drive_file_id: string
          drive_link?: string | null
          drive_web_view_link?: string | null
          file_name: string
          file_size_bytes?: number | null
          file_type: string
          id?: string
          metadata?: Json
          mime_type?: string | null
          notes?: string | null
          site_id?: string
          updated_at?: string
          uploaded_by?: string | null
          zone_id?: string | null
        }
        Update: {
          acquisition_date?: string | null
          created_at?: string
          deleted_at?: string | null
          drive_file_id?: string
          drive_link?: string | null
          drive_web_view_link?: string | null
          file_name?: string
          file_size_bytes?: number | null
          file_type?: string
          id?: string
          metadata?: Json
          mime_type?: string | null
          notes?: string | null
          site_id?: string
          updated_at?: string
          uploaded_by?: string | null
          zone_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "geospatial_files_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "geospatial_files_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_items: {
        Row: {
          category: string | null
          created_at: string
          deleted_at: string | null
          id: string
          min_threshold: number | null
          name: string
          quantity: number
          site_id: string
          sku: string | null
          unit: string
          updated_at: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          min_threshold?: number | null
          name: string
          quantity?: number
          site_id?: string
          sku?: string | null
          unit?: string
          updated_at?: string
        }
        Update: {
          category?: string | null
          created_at?: string
          deleted_at?: string | null
          id?: string
          min_threshold?: number | null
          name?: string
          quantity?: number
          site_id?: string
          sku?: string | null
          unit?: string
          updated_at?: string
        }
        Relationships: []
      }
      land_clearing_records: {
        Row: {
          actual_area: number
          cleared_at: string
          cleared_by: string | null
          created_at: string
          daily_log_id: string | null
          deleted_at: string | null
          id: string
          method: string | null
          plan_area: number
          site_id: string
          updated_at: string
          zone_id: string
        }
        Insert: {
          actual_area?: number
          cleared_at?: string
          cleared_by?: string | null
          created_at?: string
          daily_log_id?: string | null
          deleted_at?: string | null
          id?: string
          method?: string | null
          plan_area?: number
          site_id?: string
          updated_at?: string
          zone_id: string
        }
        Update: {
          actual_area?: number
          cleared_at?: string
          cleared_by?: string | null
          created_at?: string
          daily_log_id?: string | null
          deleted_at?: string | null
          id?: string
          method?: string | null
          plan_area?: number
          site_id?: string
          updated_at?: string
          zone_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "land_clearing_records_cleared_by_fkey"
            columns: ["cleared_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "land_clearing_records_daily_log_id_fkey"
            columns: ["daily_log_id"]
            isOneToOne: false
            referencedRelation: "daily_logs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "land_clearing_records_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "zones"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          birthdate: string | null
          created_at: string
          deleted_at: string | null
          email: string
          emergency_contact_name: string | null
          emergency_contact_phone: string | null
          gender: string | null
          id: string
          is_active: boolean
          name: string
          national_id: string | null
          phone: string | null
          role: Database["public"]["Enums"]["user_role"]
          site_id: string
          updated_at: string
        }
        Insert: {
          birthdate?: string | null
          created_at?: string
          deleted_at?: string | null
          email: string
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          gender?: string | null
          id: string
          is_active?: boolean
          name: string
          national_id?: string | null
          phone?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          site_id?: string
          updated_at?: string
        }
        Update: {
          birthdate?: string | null
          created_at?: string
          deleted_at?: string | null
          email?: string
          emergency_contact_name?: string | null
          emergency_contact_phone?: string | null
          gender?: string | null
          id?: string
          is_active?: boolean
          name?: string
          national_id?: string | null
          phone?: string | null
          role?: Database["public"]["Enums"]["user_role"]
          site_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      zones: {
        Row: {
          category: string | null
          created_at: string
          deleted_at: string | null
          description: string | null
          id: string
          name: string
          site_id: string
          updated_at: string
        }
        Insert: {
          category?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          id?: string
          name: string
          site_id?: string
          updated_at?: string
        }
        Update: {
          category?: string | null
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          id?: string
          name?: string
          site_id?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      current_user_role: {
        Args: never
        Returns: Database["public"]["Enums"]["user_role"]
      }
    }
    Enums: {
      attendance_status: "present" | "absent" | "sick" | "leave"
      equipment_type: "gnss" | "total_station" | "drone"
      log_status: "draft" | "submitted" | "approved"
      user_role: "supervisor" | "foreman" | "crew"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {
      attendance_status: ["present", "absent", "sick", "leave"],
      equipment_type: ["gnss", "total_station", "drone"],
      log_status: ["draft", "submitted", "approved"],
      user_role: ["supervisor", "foreman", "crew"],
    },
  },
} as const
