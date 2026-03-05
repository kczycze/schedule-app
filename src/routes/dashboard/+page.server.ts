export const load = async ({ locals }) => {

  const { supabase, session } = locals;

  if (!session) {
    return { bookings: [] };
  }

  const { data: companies } = await supabase
    .from('companies')
    .select('id')
    .eq('owner_id', session.user.id)
    .single();

  if (!companies) {
    return { bookings: [] };
  }

  const { data: bookings } = await supabase
    .from('bookings')
    .select('*')
    .eq('company_id', companies.id)
    .order('booking_date', { ascending: false });

  return {
    bookings
  };
};