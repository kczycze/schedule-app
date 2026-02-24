// Database types for existing schema

export interface Company {
  id: string;
  name: string;
  slug: string;
  owner_id?: string;
  created_at?: string;
}

export interface Service {
  id: string;
  company_id: string;
  name: string;
  duration_minutes: number;
  price: number;
  created_at?: string;
}

export interface Booking {
  id: string;
  company_id: string;
  service_id: string;
  booking_date: string; // Format: YYYY-MM-DD
  start_time: string; // Format: HH:MM
  customer_name: string;
  customer_email: string;
  status?: string; // 'pending' | 'confirmed' | 'cancelled'
  created_at?: string;
}

// Component props types

export interface CalendarDay {
  date: Date;
  isCurrentMonth: boolean;
  isToday: boolean;
  isPast: boolean;
  isSelected: boolean;
}