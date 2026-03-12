<script>
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';

	export let data;
	export let form;

	$: ({ employees, services } = data);

	let showAddForm = false;
	let deletingId  = null;    // ID pracownika oczekującego na potwierdzenie usunięcia

	// Zamknij formularz po udanym dodaniu
	$: if (form?.success && form?.action === 'add') {
		showAddForm = false;
	}
</script>

<svelte:head>
	<title>Pracownicy — Dashboard</title>
</svelte:head>

<!-- ── NAGŁÓWEK SEKCJI ──────────────────────────────────────────────────── -->
<div class="section-header">
	<div>
		<h1>Pracownicy</h1>
		<p class="subtitle">Zarządzaj zespołem i przypisuj im usługi</p>
	</div>
	<button class="btn-primary" on:click={() => (showAddForm = !showAddForm)}>
		{showAddForm ? '✕ Anuluj' : '+ Dodaj pracownika'}
	</button>
</div>

<!-- ── FORMULARZ DODAWANIA ───────────────────────────────────────────────── -->
{#if showAddForm}
	<div class="card form-card">
		<h2>Nowy pracownik</h2>

		{#if form?.action === 'add' && form?.error}
			<p class="error-msg">{form.error}</p>
		{/if}

		<form method="POST" action="?/add" use:enhance>
			<div class="form-row">
				<div class="form-group">
					<label for="name">Imię i nazwisko *</label>
					<input
						id="name"
						name="name"
						type="text"
						placeholder="np. Jan Kowalski"
						value={form?.values?.name ?? ''}
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
						placeholder="jan@firma.pl"
						value={form?.values?.email ?? ''}
					/>
				</div>
			</div>
			<div class="form-actions">
				<button type="submit" class="btn-primary">Dodaj pracownika</button>
				<button type="button" class="btn-ghost" on:click={() => (showAddForm = false)}>
					Anuluj
				</button>
			</div>
		</form>
	</div>
{/if}

<!-- ── LISTA PRACOWNIKÓW ─────────────────────────────────────────────────── -->
{#if employees.length === 0}
	<div class="empty-state">
		<span class="empty-icon">👥</span>
		<h3>Brak pracowników</h3>
		<p>Dodaj pierwszego pracownika, aby włączyć rezerwacje przypisane do osoby.</p>
		<button class="btn-primary" on:click={() => (showAddForm = true)}>
			+ Dodaj pracownika
		</button>
	</div>
{:else}
	<div class="employees-grid">
		{#each employees as employee (employee.id)}
			<div class="employee-card" class:inactive={!employee.is_active}>

				<!-- Awatar inicjałowy -->
				<div class="avatar">
					{employee.name.charAt(0).toUpperCase()}
				</div>

				<!-- Dane pracownika -->
				<div class="employee-info">
					<div class="employee-name-row">
						<h3>{employee.name}</h3>
						<span class="badge" class:badge-active={employee.is_active} class:badge-inactive={!employee.is_active}>
							{employee.is_active ? 'Aktywny' : 'Nieaktywny'}
						</span>
					</div>
					{#if employee.email}
						<p class="employee-email">{employee.email}</p>
					{/if}
					<p class="services-count">
						{employee.employee_services.length}
						{employee.employee_services.length === 1 ? 'usługa' : 'usług'}
					</p>
				</div>

				<!-- Akcje -->
				<div class="employee-actions">
					<a href="/dashboard/employees/{employee.id}" class="btn-secondary">
						✏️ Edytuj
					</a>

					<!-- Przełącz aktywność -->
					<form method="POST" action="?/toggleActive" use:enhance>
						<input type="hidden" name="employee_id" value={employee.id} />
						<input type="hidden" name="is_active" value={!employee.is_active} />
						<button type="submit" class="btn-ghost">
							{employee.is_active ? '⏸ Dezaktywuj' : '▶ Aktywuj'}
						</button>
					</form>

					<!-- Usuń z potwierdzeniem -->
					{#if deletingId === employee.id}
						<div class="confirm-delete">
							<span>Na pewno?</span>
							<form method="POST" action="?/delete" use:enhance>
								<input type="hidden" name="employee_id" value={employee.id} />
								<button type="submit" class="btn-danger">Tak, usuń</button>
							</form>
							<button class="btn-ghost" on:click={() => (deletingId = null)}>Anuluj</button>
						</div>
					{:else}
						<button class="btn-danger-ghost" on:click={() => (deletingId = employee.id)}>
							🗑 Usuń
						</button>
					{/if}
				</div>

			</div>
		{/each}
	</div>
{/if}

<!-- ── STYLE ─────────────────────────────────────────────────────────────── -->
<style>
	/* Nagłówek sekcji */
	.section-header {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: 1rem;
		margin-bottom: 1.5rem;
	}
	.section-header h1 { margin: 0; font-size: 1.5rem; color: #1e3a5f; }
	.subtitle { margin: 0.25rem 0 0; color: #64748b; font-size: 0.9rem; }

	/* Karty */
	.card { background: #fff; border: 1px solid #e2e8f0; border-radius: 10px; padding: 1.5rem; }
	.form-card { margin-bottom: 1.5rem; }
	.form-card h2 { margin: 0 0 1.25rem; font-size: 1.1rem; color: #1e3a5f; }

	/* Formularz */
	.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
	.form-group { display: flex; flex-direction: column; gap: 0.4rem; }
	label { font-size: 0.875rem; font-weight: 600; color: #374151; }
	input[type="text"],
	input[type="email"] {
		padding: 0.55rem 0.75rem;
		border: 1px solid #cbd5e1;
		border-radius: 6px;
		font-size: 0.9rem;
		transition: border-color 0.15s;
	}
	input:focus { outline: none; border-color: #2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,0.12); }
	.form-actions { display: flex; gap: 0.75rem; margin-top: 1.25rem; }

	/* Siatka pracowników */
	.employees-grid { display: flex; flex-direction: column; gap: 0.75rem; }

	.employee-card {
		display: flex;
		align-items: center;
		gap: 1.25rem;
		background: #fff;
		border: 1px solid #e2e8f0;
		border-radius: 10px;
		padding: 1rem 1.25rem;
		transition: box-shadow 0.15s;
	}
	.employee-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.07); }
	.employee-card.inactive { opacity: 0.6; }

	/* Awatar */
	.avatar {
		width: 42px;
		height: 42px;
		border-radius: 50%;
		background: #2563eb;
		color: #fff;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 1.1rem;
		font-weight: 700;
		flex-shrink: 0;
	}

	/* Info */
	.employee-info { flex: 1; min-width: 0; }
	.employee-name-row { display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap; }
	.employee-name-row h3 { margin: 0; font-size: 1rem; color: #1e293b; }
	.employee-email { margin: 0.2rem 0 0; font-size: 0.85rem; color: #64748b; }
	.services-count { margin: 0.2rem 0 0; font-size: 0.8rem; color: #94a3b8; }

	/* Badge status */
	.badge { font-size: 0.75rem; font-weight: 600; padding: 0.2rem 0.6rem; border-radius: 20px; }
	.badge-active   { background: #dcfce7; color: #16a34a; }
	.badge-inactive { background: #f1f5f9; color: #64748b; }

	/* Akcje */
	.employee-actions { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }

	/* Potwierdzenie usunięcia */
	.confirm-delete { display: flex; align-items: center; gap: 0.5rem; }
	.confirm-delete span { font-size: 0.85rem; color: #dc2626; font-weight: 600; }

	/* Stan pusty */
	.empty-state {
		text-align: center;
		padding: 3rem 1rem;
		background: #f8fafc;
		border: 2px dashed #cbd5e1;
		border-radius: 12px;
	}
	.empty-icon { font-size: 2.5rem; display: block; margin-bottom: 0.75rem; }
	.empty-state h3 { margin: 0 0 0.5rem; color: #374151; }
	.empty-state p  { margin: 0 0 1.5rem; color: #64748b; font-size: 0.9rem; }

	/* Komunikat błędu */
	.error-msg {
		background: #fef2f2;
		color: #dc2626;
		border: 1px solid #fecaca;
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

	.btn-secondary {
		background: #f1f5f9;
		color: #374151;
		border: 1px solid #e2e8f0;
		padding: 0.45rem 0.9rem;
		border-radius: 6px;
		font-size: 0.8rem;
		font-weight: 600;
		cursor: pointer;
		text-decoration: none;
		display: inline-flex;
		align-items: center;
		gap: 0.3rem;
		transition: background 0.15s;
	}
	.btn-secondary:hover { background: #e2e8f0; }

	.btn-ghost {
		background: transparent;
		color: #64748b;
		border: 1px solid #e2e8f0;
		padding: 0.45rem 0.9rem;
		border-radius: 6px;
		font-size: 0.8rem;
		cursor: pointer;
		transition: background 0.15s;
	}
	.btn-ghost:hover { background: #f8fafc; }

	.btn-danger {
		background: #dc2626;
		color: #fff;
		border: none;
		padding: 0.45rem 0.9rem;
		border-radius: 6px;
		font-size: 0.8rem;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.15s;
	}
	.btn-danger:hover { background: #b91c1c; }

	.btn-danger-ghost {
		background: transparent;
		color: #dc2626;
		border: 1px solid #fecaca;
		padding: 0.45rem 0.9rem;
		border-radius: 6px;
		font-size: 0.8rem;
		cursor: pointer;
		transition: background 0.15s;
	}
	.btn-danger-ghost:hover { background: #fef2f2; }

	@media (max-width: 640px) {
		.form-row { grid-template-columns: 1fr; }
		.employee-card { flex-direction: column; align-items: flex-start; }
		.employee-actions { width: 100%; }
	}
</style>