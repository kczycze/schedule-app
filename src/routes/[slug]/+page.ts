import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';
import { supabase } from '$lib/supabaseClient';

export const load: PageLoad = async ({ params }) => {
  const { slug } = params;

  // Fetch company by slug
  const { data: company, error: companyError } = await supabase
    .from('companies')
    .select('id, slug, name, booking_approval')
    .eq('slug', slug)
    .single();

  if (companyError || !company) {
    throw error(404, 'Company not found');
  }

  // Fetch services for this company
  const { data: services, error: servicesError } = await supabase
    .from('services')
    .select('id, name, duration_minutes, price')
    .eq('company_id', company.id)
    .order('name');

  if (servicesError) {
    throw error(500, 'Failed to load services');
  }

  const { data: availability } = await supabase
    .from('availability_settings')
    .select('working_days, work_start, work_end, slot_duration')
    .eq('company_id', company.id)
    .single();

  const { data: blockedPeriods } = await supabase
    .from('blocked_periods')
    .select('starts_at, ends_at, employee_id')
    .eq('company_id', company.id);
 
  return {
    company,
    services: services || [],
    availability: availability ?? {
      working_days:  [1, 2, 3, 4, 5],
      work_start:    '09:00',
      work_end:      '17:00',
      slot_duration: 30
    },
    blockedPeriods: blockedPeriods ?? []
  };
}