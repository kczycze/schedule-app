<script>
	import { enhance } from '$app/forms';
	import { page } from '$app/stores';

	export let data;
	export let form;

	$: ({ employee, services, assignedServiceIds } = data);

	// Lokalny zestaw zaznaczonych usług (reaguje na zapis)
	let selected = new Set(assignedServiceIds);

	$: if (form?.success && form?.action === 'assignServices') {
		// Po zapisie odśwież lokalny stan z serwera
		selected = new Set(assignedServiceIds);
	}

	function toggleService(id) {
		const next = new Set(selected);
		next.has(id) ? next.delete(id) : next.add(id);
		selected = next;
	}

	// Formatowanie ceny
	function formatPrice(price) {
		if (price == null) return 'bezpłatna';
		return new Intl.NumberFormat('pl-PL', {
			style: 'currency',
			currency: 'PLN'
		}).format(price);
	}
</script>

<svelte:head>
	<title>Edycja pracownika — Dashboard</title>
</svelte:head>

<!-- ── NAWIGACJA WSTECZ ──────────────────────────────────────────────────── -->
<div class="breadcrumb">
	<a href="/dashboard/employees">← Pracownicy</a>
	<span>/</span>
	<span>{employee.name}</span>
</div>

<div class="page-grid">

	<!-- ── LEWA KOLUMNA: dane pracownika ────────────────────────────────── -->
	<section class="card">
		<h2>Dane pracownika</h2>

		{#if form?.action === 'update' && form?.error}
			<p class="error-msg">{form.error}</p>
		{/if}
		{#if form?.action === 'update' && form?.success}
			<p class="success-msg">✓ Zmiany zapisane.</p>
		{/if}

		<form method="POST" action="?/update" use:enhance>
			<div class="form-group">
				<label for="name">Imię i nazwisko *</label>
				<input
					id="name"
					name="name"
					type="text"
					value={form?.values?.name ?? employee.name}
					required
					minlength="2"
				/>
			</div>

			<div class="form-group">
				<label for="email">Email (opcjonalnie)</label>
				<input
					id="email"
					name="email"
					type="email"
					value={form?.values?.email ?? employee.email ?? ''}
					placeholder="pracownik@firma.pl"
				/>
			</div>

			<div class="status-row">
				<span class="label-text">Status</span>
				<span class="badge" class:badge-active={employee.is_active} class:badge-inactive={!employee.is_active}>
					{employee.is_active ? 'Aktywny' : 'Nieaktywny'}
				</span>
				<a href="/dashboard/employees" class="hint">
					(zmień na liście pracowników)
				</a>
			</div>

			<button type="submit" class="btn-primary">
				💾 Zapisz dane
			</button>
		</form>
	</section>

	<!-- ── PRAWA KOLUMNA: usługi ─────────────────────────────────────────── -->
	<section class="card">
		<h2>Przypisane usługi</h2>
		<p class="section-hint">
			Zaznacz usługi, które może świadczyć ten pracownik.
		</p>

		{#if form?.action === 'assignServices' && form?.error}
			<p class="error-msg">{form.error}</p>
		{/if}
		{#if form?.action === 'assignServices' && form?.success}
			<p class="success-msg">✓ Usługi zaktualizowane.</p>
		{/if}

		{#if services.length === 0}
			<div class="empty-services">
				<p>Brak usług w firmie.</p>
				<a href="/dashboard/services">→ Dodaj usługi</a>
			</div>
		{:else}
			<form method="POST" action="?/assignServices" use:enhance>
				<div class="services-list">
					{#each services as service (service.id)}
						<label
							class="service-item"
							class:service-selected={selected.has(service.id)}
						>
							<input
								type="checkbox"
								name="service_ids"
								value={service.id}
								checked={selected.has(service.id)}
								on:change={() => toggleService(service.id)}
							/>
							<div class="service-info">
								<span class="service-name">{service.name}</span>
								<span class="service-meta">
									{service.duration_minutes} min
									·
									{formatPrice(service.price)}
								</span>
							</div>
							{#if selected.has(service.id)}
								<span class="check-icon">✓</span>
							{/if}
						</label>
					{/each}
				</div>

				<div class="services-footer">
					<span class="selected-count">
						{selected.size} z {services.length} usług zaznaczonych
					</span>
					<button type="submit" class="btn-primary">
						💾 Zapisz usługi
					</button>
				</div>
			</form>
		{/if}
	</section>

</div>

<!-- ── STYLE ─────────────────────────────────────────────────────────────── -->
<style>
	/* Breadcrumb */
	.breadcrumb {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.875rem;
		color: #64748b;
		margin-bottom: 1.5rem;
	}
	.breadcrumb a { color: #2563eb; text-decoration: none; }
	.breadcrumb a:hover { text-decoration: underline; }

	/* Siatka dwukolumnowa */
	.page-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1.25rem;
		align-items: start;
	}

	/* Karta */
	.card {
		background: #fff;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		padding: 1.5rem;
	}
	.card h2 {
		margin: 0 0 1.25rem;
		font-size: 1.1rem;
		color: #1e3a5f;
		padding-bottom: 0.75rem;
		border-bottom: 1px solid #f1f5f9;
	}
	.section-hint { margin: -0.75rem 0 1rem; font-size: 0.85rem; color: #64748b; }

	/* Formularz */
	.form-group { display: flex; flex-direction: column; gap: 0.4rem; margin-bottom: 1rem; }
	label { font-size: 0.875rem; font-weight: 600; color: #374151; }
	.label-text { font-size: 0.875rem; font-weight: 600; color: #374151; }
	input[type="text"],
	input[type="email"] {
		padding: 0.55rem 0.75rem;
		border: 1px solid #cbd5e1;
		border-radius: 6px;
		font-size: 0.9rem;
		transition: border-color 0.15s;
	}
	input:focus { outline: none; border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,0.12); }

	/* Status row */
	.status-row {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 1.25rem;
	}
	.hint { font-size: 0.8rem; color: #94a3b8; text-decoration: none; }
	.hint:hover { text-decoration: underline; }

	/* Badge */
	.badge { font-size: 0.75rem; font-weight: 600; padding: 0.2rem 0.6rem; border-radius: 20px; }
	.badge-active   { background: #dcfce7; color: #16a34a; }
	.badge-inactive { background: #f1f5f9; color: #64748b; }

	/* Lista usług */
	.services-list { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 1rem; }

	.service-item {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 0.75rem;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
		cursor: pointer;
		transition: background 0.12s, border-color 0.12s;
		user-select: none;
	}
	.service-item:hover { background: #f8fafc; }
	.service-item.service-selected {
		border-color: #2563eb;
		background: #eff6ff;
	}

	.service-item input[type="checkbox"] {
		width: 16px;
		height: 16px;
		accent-color: #2563eb;
		cursor: pointer;
		flex-shrink: 0;
	}

	.service-info { flex: 1; min-width: 0; }
	.service-name { display: block; font-size: 0.9rem; font-weight: 600; color: #1e293b; }
	.service-meta { display: block; font-size: 0.78rem; color: #64748b; margin-top: 0.15rem; }

	.check-icon { color: #2563eb; font-weight: 700; margin-left: auto; flex-shrink: 0; }

	/* Footer usług */
	.services-footer {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding-top: 0.75rem;
		border-top: 1px solid #f1f5f9;
	}
	.selected-count { font-size: 0.82rem; color: #64748b; }

	/* Pusty stan usług */
	.empty-services {
		text-align: center;
		padding: 2rem 1rem;
		background: #f8fafc;
		border: 2px dashed #cbd5e1;
		border-radius: 8px;
	}
	.empty-services p { margin: 0 0 0.5rem; color: #64748b; }
	.empty-services a { color: #2563eb; text-decoration: none; font-weight: 600; }

	/* Komunikaty */
	.error-msg {
		background: #fef2f2;
		color: #dc2626;
		border: 1px solid #fecaca;
		border-radius: 6px;
		padding: 0.6rem 0.9rem;
		font-size: 0.875rem;
		margin-bottom: 1rem;
	}
	.success-msg {
		background: #f0fdf4;
		color: #16a34a;
		border: 1px solid #bbf7d0;
		border-radius: 6px;
		padding: 0.6rem 0.9rem;
		font-size: 0.875rem;
		margin-bottom: 1rem;
	}

	/* Przyciski */
	.btn-primary {
		background: #2563eb;
		color: #fff;
		border: none;
		padding: 0.55rem 1.1rem;
		border-radius: 6px;
		font-size: 0.875rem;
		font-weight: 600;
		cursor: pointer;
		text-decoration: none;
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		transition: background 0.15s;
	}
	.btn-primary:hover { background: #1d4ed8; }

	@media (max-width: 768px) {
		.page-grid { grid-template-columns: 1fr; }
	}
</style>