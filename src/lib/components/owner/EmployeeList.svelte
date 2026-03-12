<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  export let companyId;

  // ── Stan ────────────────────────────────────────────────────────────────
  let employees   = [];
  let services    = [];   // wszystkie usługi firmy (do przypisywania)
  let loading     = true;

  // Formularz dodawania
  let showAddForm = false;
  let newName     = '';
  let newEmail    = '';
  let addError    = '';

  // Edycja usług — id pracownika którego panel jest otwarty
  let expandedId  = null;

  // Zestaw zaznaczonych usług dla aktualnie otwartego pracownika
  let selectedServices = new Set();

  // Potwierdzenie usunięcia
  let deletingId  = null;

  // ── Ładowanie danych ─────────────────────────────────────────────────────
  async function loadData() {
    loading = true;

    const [{ data: empData }, { data: svcData }] = await Promise.all([
      supabase
        .from('employees')
        .select('id, name, email, is_active, employee_services ( service_id )')
        .eq('company_id', companyId)
        .order('created_at', { ascending: true }),

      supabase
        .from('services')
        .select('id, name, duration_minutes')
        .eq('company_id', companyId)
        .order('name', { ascending: true })
    ]);

    employees = empData ?? [];
    services  = svcData ?? [];
    loading   = false;
  }

  onMount(loadData);

  // ── Dodaj pracownika ─────────────────────────────────────────────────────
  async function addEmployee() {
    addError = '';
    const name = newName.trim();

    if (name.length < 2) {
      addError = 'Imię musi mieć co najmniej 2 znaki.';
      return;
    }

    const { error } = await supabase
      .from('employees')
      .insert({ company_id: companyId, name, email: newEmail.trim() || null });

    if (error) {
      addError = 'Nie udało się dodać pracownika.';
      return;
    }

    newName = '';
    newEmail = '';
    showAddForm = false;
    await loadData();
  }

  // ── Przełącz aktywność ───────────────────────────────────────────────────
  async function toggleActive(employee) {
    await supabase
      .from('employees')
      .update({ is_active: !employee.is_active })
      .eq('id', employee.id);

    await loadData();
  }

  // ── Usuń pracownika ──────────────────────────────────────────────────────
  async function deleteEmployee(id) {
    await supabase.from('employees').delete().eq('id', id);
    deletingId = null;
    if (expandedId === id) expandedId = null;
    await loadData();
  }

  // ── Rozwiń / zwiń panel usług ────────────────────────────────────────────
  function toggleExpand(employee) {
    if (expandedId === employee.id) {
      expandedId = null;
      return;
    }
    expandedId = employee.id;
    selectedServices = new Set(employee.employee_services.map(es => es.service_id));
  }

  // ── Zapisz przypisane usługi ─────────────────────────────────────────────
  async function saveServices(employeeId) {
    // Atomowo: usuń stare, wstaw nowe
    await supabase.from('employee_services').delete().eq('employee_id', employeeId);

    if (selectedServices.size > 0) {
      await supabase.from('employee_services').insert(
        [...selectedServices].map(service_id => ({ employee_id: employeeId, service_id }))
      );
    }

    await loadData();
    expandedId = null;
  }
</script>

<!-- ── LISTA PRACOWNIKÓW ───────────────────────────────────────────────────── -->
{#if loading}
  <p>Ładowanie pracowników...</p>

{:else}

  <!-- Formularz dodawania -->
  {#if showAddForm}
    <div class="add-form">
      {#if addError}<p class="error">{addError}</p>{/if}
      <div class="add-row">
        <input
          type="text"
          placeholder="Imię i nazwisko *"
          bind:value={newName}
          minlength="2"
        />
        <input
          type="email"
          placeholder="Email (opcjonalnie)"
          bind:value={newEmail}
        />
        <button class="btn-primary" on:click={addEmployee}>Dodaj</button>
        <button class="btn-ghost" on:click={() => { showAddForm = false; addError = ''; }}>Anuluj</button>
      </div>
    </div>
  {:else}
    <button class="btn-primary" on:click={() => (showAddForm = true)}>
      + Dodaj pracownika
    </button>
  {/if}

  <!-- Pusta lista -->
  {#if employees.length === 0}
    <p class="empty">Brak pracowników.</p>

  {:else}
    <ul class="employee-list">
      {#each employees as emp (emp.id)}
        <li class="employee-item" class:inactive={!emp.is_active}>

          <!-- Wiersz główny -->
          <div class="emp-row">
            <div class="emp-avatar">{emp.name.charAt(0).toUpperCase()}</div>

            <div class="emp-info">
              <strong>{emp.name}</strong>
              {#if emp.email}<span class="emp-email">{emp.email}</span>{/if}
              <span class="emp-services-count">
                {emp.employee_services.length} usług
              </span>
            </div>

            <div class="emp-actions">
              <!-- Przypisz usługi -->
              <button
                class="btn-ghost"
                on:click={() => toggleExpand(emp)}
              >
                {expandedId === emp.id ? '▲ Usługi' : '▼ Usługi'}
              </button>

              <!-- Aktywny / nieaktywny -->
              <button class="btn-ghost" on:click={() => toggleActive(emp)}>
                {emp.is_active ? '⏸ Dezaktywuj' : '▶ Aktywuj'}
              </button>

              <!-- Usuń -->
              {#if deletingId === emp.id}
                <span class="confirm-label">Na pewno?</span>
                <button class="btn-danger" on:click={() => deleteEmployee(emp.id)}>Tak</button>
                <button class="btn-ghost" on:click={() => (deletingId = null)}>Nie</button>
              {:else}
                <button class="btn-danger-ghost" on:click={() => (deletingId = emp.id)}>🗑</button>
              {/if}
            </div>
          </div>

          <!-- Panel usług (rozwijany) -->
          {#if expandedId === emp.id}
            <div class="services-panel">
              {#if services.length === 0}
                <p class="empty">Brak usług w firmie.</p>
              {:else}
                <p class="panel-label">Zaznacz usługi dla tego pracownika:</p>
                <div class="services-checkboxes">
                  {#each services as svc (svc.id)}
                    <label class="svc-option" class:svc-checked={selectedServices.has(svc.id)}>
                      <input
                        type="checkbox"
                        checked={selectedServices.has(svc.id)}
                        on:change={() => {
                          const next = new Set(selectedServices);
                          next.has(svc.id) ? next.delete(svc.id) : next.add(svc.id);
                          selectedServices = next;
                        }}
                      />
                      {svc.name}
                      <span class="svc-dur">{svc.duration_minutes} min</span>
                    </label>
                  {/each}
                </div>
                <button class="btn-primary" on:click={() => saveServices(emp.id)}>
                  💾 Zapisz usługi
                </button>
              {/if}
            </div>
          {/if}

        </li>
      {/each}
    </ul>
  {/if}
{/if}

<!-- ── STYLE ──────────────────────────────────────────────────────────────── -->
<style>
  /* Przycisk dodaj */
  .btn-primary {
    background: #1a73e8;
    color: #fff;
    border: none;
    padding: 0.4rem 0.9rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.85rem;
    font-weight: 600;
  }
  .btn-primary:hover { background: #1558b0; }

  .btn-ghost {
    background: transparent;
    color: #555;
    border: 1px solid #ddd;
    padding: 0.35rem 0.75rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.8rem;
  }
  .btn-ghost:hover { background: #f5f5f5; }

  .btn-danger {
    background: #e53935;
    color: #fff;
    border: none;
    padding: 0.35rem 0.75rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.8rem;
    font-weight: 600;
  }
  .btn-danger-ghost {
    background: transparent;
    color: #e53935;
    border: 1px solid #ffcdd2;
    padding: 0.35rem 0.6rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.8rem;
  }
  .btn-danger-ghost:hover { background: #fff5f5; }

  /* Formularz dodawania */
  .add-form { margin-bottom: 0.75rem; }
  .add-row {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
    align-items: center;
    margin-top: 0.5rem;
  }
  .add-row input {
    flex: 1;
    min-width: 130px;
    padding: 0.4rem 0.6rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 0.85rem;
  }
  .add-row input:focus { outline: none; border-color: #1a73e8; }

  /* Lista */
  .employee-list {
    list-style: none;
    padding: 0;
    margin: 0.75rem 0 0;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .employee-item {
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    overflow: hidden;
    transition: opacity 0.2s;
  }
  .employee-item.inactive { opacity: 0.55; }

  .emp-row {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.6rem 0.75rem;
  }

  .emp-avatar {
    width: 34px;
    height: 34px;
    border-radius: 50%;
    background: #1a73e8;
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 700;
    font-size: 0.95rem;
    flex-shrink: 0;
  }

  .emp-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 0.1rem;
  }
  .emp-info strong { font-size: 0.9rem; color: #222; }
  .emp-email       { font-size: 0.78rem; color: #777; }
  .emp-services-count { font-size: 0.75rem; color: #aaa; }

  .emp-actions {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    flex-wrap: wrap;
  }

  .confirm-label { font-size: 0.8rem; color: #e53935; font-weight: 600; }

  /* Panel usług */
  .services-panel {
    border-top: 1px solid #eee;
    background: #fafafa;
    padding: 0.75rem;
  }
  .panel-label { font-size: 0.82rem; color: #555; margin: 0 0 0.5rem; }

  .services-checkboxes {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
    margin-bottom: 0.75rem;
  }

  .svc-option {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.4rem 0.6rem;
    border: 1px solid #e0e0e0;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.85rem;
    background: #fff;
    transition: background 0.1s, border-color 0.1s;
  }
  .svc-option:hover      { background: #f0f7ff; }
  .svc-option.svc-checked { border-color: #1a73e8; background: #e8f0fe; }
  .svc-dur { margin-left: auto; font-size: 0.75rem; color: #999; }

  /* Misc */
  .empty { color: #999; font-size: 0.85rem; margin: 0.5rem 0 0; }
  .error { color: #e53935; font-size: 0.82rem; margin: 0 0 0.4rem; }
</style>