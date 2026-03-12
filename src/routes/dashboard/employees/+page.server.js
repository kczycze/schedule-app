import { fail, redirect } from '@sveltejs/kit';

// ─── LOAD ────────────────────────────────────────────────────────────────────

export async function load({ locals }) {
	const { supabase, session } = locals;

	if (!session) throw redirect(303, '/');

	// Pobierz firmę zalogowanego właściciela
	const { data: company, error: companyError } = await supabase
		.from('companies')
		.select('id')
		.eq('owner_id', session.user.id)
		.single();

	if (companyError || !company) throw redirect(303, '/');

	// Pobierz pracowników z liczbą przypisanych usług
	const { data: employees } = await supabase
		.from('employees')
		.select(`
			id,
			name,
			email,
			is_active,
			created_at,
			employee_services ( service_id )
		`)
		.eq('company_id', company.id)
		.order('created_at', { ascending: true });

	// Pobierz wszystkie usługi firmy (do wyświetlenia w formularzu dodawania)
	const { data: services } = await supabase
		.from('services')
		.select('id, name, duration_minutes, price')
		.eq('company_id', company.id)
		.order('name', { ascending: true });

	return {
		company,
		employees: employees ?? [],
		services: services ?? []
	};
}

// ─── ACTIONS ─────────────────────────────────────────────────────────────────

export const actions = {

	// Dodaj nowego pracownika
	add: async ({ request, locals }) => {
		const { supabase, session } = locals;
		if (!session) return fail(401, { error: 'Brak autoryzacji' });

		const form = await request.formData();
		const name  = form.get('name')?.toString().trim();
		const email = form.get('email')?.toString().trim() || null;

		if (!name || name.length < 2) {
			return fail(422, {
				action: 'add',
				error: 'Imię i nazwisko musi mieć co najmniej 2 znaki.',
				values: { name, email }
			});
		}

		const { data: company } = await supabase
			.from('companies')
			.select('id')
			.eq('owner_id', session.user.id)
			.single();

		if (!company) return fail(403, { error: 'Brak dostępu.' });

		const { error } = await supabase
			.from('employees')
			.insert({ company_id: company.id, name, email });

		if (error) {
			return fail(500, {
				action: 'add',
				error: 'Nie udało się dodać pracownika.',
				values: { name, email }
			});
		}

		return { success: true, action: 'add' };
	},

	// Przełącz aktywność pracownika (aktywny / nieaktywny)
	toggleActive: async ({ request, locals }) => {
		const { supabase, session } = locals;
		if (!session) return fail(401);

		const form       = await request.formData();
		const employeeId = form.get('employee_id')?.toString();
		const isActive   = form.get('is_active') === 'true';

		if (!employeeId) return fail(422, { error: 'Brak ID pracownika.' });

		const { error } = await supabase
			.from('employees')
			.update({ is_active: isActive })
			.eq('id', employeeId)
			.eq('company_id', (
				await supabase
					.from('companies')
					.select('id')
					.eq('owner_id', session.user.id)
					.single()
			).data?.id);

		if (error) return fail(500, { error: 'Nie udało się zmienić statusu.' });

		return { success: true, action: 'toggleActive' };
	},

	// Usuń pracownika
	delete: async ({ request, locals }) => {
		const { supabase, session } = locals;
		if (!session) return fail(401);

		const form       = await request.formData();
		const employeeId = form.get('employee_id')?.toString();

		if (!employeeId) return fail(422, { error: 'Brak ID pracownika.' });

		// RLS pilnuje że owner usuwa tylko swoich pracowników
		const { error } = await supabase
			.from('employees')
			.delete()
			.eq('id', employeeId);

		if (error) return fail(500, { error: 'Nie udało się usunąć pracownika.' });

		return { success: true, action: 'delete' };
	}
};