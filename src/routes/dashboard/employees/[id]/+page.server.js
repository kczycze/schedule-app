import { fail, redirect } from '@sveltejs/kit';

// ─── LOAD ────────────────────────────────────────────────────────────────────

export async function load({ locals, params }) {
	const { supabase, session } = locals;

	if (!session) throw redirect(303, '/');

	// Pobierz firmę właściciela
	const { data: company } = await supabase
		.from('companies')
		.select('id')
		.eq('owner_id', session.user.id)
		.single();

	if (!company) throw redirect(303, '/');

	// Pobierz pracownika — RLS gwarantuje, że to pracownik tej firmy
	const { data: employee, error } = await supabase
		.from('employees')
		.select(`
			id,
			name,
			email,
			is_active,
			employee_services ( service_id )
		`)
		.eq('id', params.id)
		.eq('company_id', company.id)
		.single();

	// Jeśli pracownik nie istnieje lub nie należy do tej firmy
	if (error || !employee) throw redirect(303, '/dashboard/employees');

	// Wszystkie usługi firmy (do checkboxów)
	const { data: services } = await supabase
		.from('services')
		.select('id, name, duration_minutes, price')
		.eq('company_id', company.id)
		.order('name', { ascending: true });

	// ID usług już przypisanych do pracownika
	const assignedServiceIds = employee.employee_services.map((es) => es.service_id);

	return {
		employee,
		services:           services ?? [],
		assignedServiceIds
	};
}

// ─── ACTIONS ─────────────────────────────────────────────────────────────────

export const actions = {

	// Zapisz dane pracownika (imię, email)
	update: async ({ request, locals, params }) => {
		const { supabase, session } = locals;
		if (!session) return fail(401);

		const form  = await request.formData();
		const name  = form.get('name')?.toString().trim();
		const email = form.get('email')?.toString().trim() || null;

		if (!name || name.length < 2) {
			return fail(422, {
				action: 'update',
				error: 'Imię i nazwisko musi mieć co najmniej 2 znaki.',
				values: { name, email }
			});
		}

		const { error } = await supabase
			.from('employees')
			.update({ name, email })
			.eq('id', params.id);

		if (error) {
			return fail(500, {
				action: 'update',
				error: 'Nie udało się zapisać zmian.',
				values: { name, email }
			});
		}

		return { success: true, action: 'update' };
	},

	// Zapisz przypisanie usług do pracownika
	assignServices: async ({ request, locals, params }) => {
		const { supabase, session } = locals;
		if (!session) return fail(401);

		const form       = await request.formData();
		const serviceIds = form.getAll('service_ids').map(String);

		// Usuń wszystkie obecne przypisania
		const { error: deleteError } = await supabase
			.from('employee_services')
			.delete()
			.eq('employee_id', params.id);

		if (deleteError) {
			return fail(500, {
				action: 'assignServices',
				error: 'Nie udało się zaktualizować usług.'
			});
		}

		// Wstaw nowe przypisania (jeśli jakiekolwiek zaznaczono)
		if (serviceIds.length > 0) {
			const rows = serviceIds.map((service_id) => ({
				employee_id: params.id,
				service_id
			}));

			const { error: insertError } = await supabase
				.from('employee_services')
				.insert(rows);

			if (insertError) {
				return fail(500, {
					action: 'assignServices',
					error: 'Nie udało się przypisać usług.'
				});
			}
		}

		return { success: true, action: 'assignServices' };
	}
};