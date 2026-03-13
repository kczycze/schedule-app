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

  return {
    company,
    services: services || []
  };
};