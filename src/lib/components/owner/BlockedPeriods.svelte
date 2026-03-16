<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  export let companyId;

  // ── Stan ─────────────────────────────────────────────────────────────────
  let blocks     = [];
  let employees  = [];
  let loading    = true;
  let saving     = false;
  let saveError  = '';

  // Formularz nowej blokady
  let newStartsAt   = '';
  let newEndsAt     = '';
  let newReason     = '';
  let newEmployeeId = '';   // '' = cała firma

  let deletingId = null;    // potwierdzenie usunięcia

  // ── Ładowanie ────────────────────────────────────────────────────────────
  async function loadData() {
    loading = true;

    const [{ data: blocksData }, { data: empData }] = await Promise.all([
      supabase
        .from('blocked_periods')
        .select('id, starts_at, ends_at, reason, employee_id, employees ( name )')
        .eq('company_id', companyId)
        .order('starts_at', { ascending: true }),

      supabase
        .from('employees')
        .select('id, name')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('name', { ascending: true })
    ]);

    blocks    = blocksData  ?? [];
    employees = empData     ?? [];
    loading   = false;
  }

  onMount(loadData);

  // ── Dodaj blokadę ─────────────────────────────────────────────────────────
  async function addBlock() {
    saveError = '';

    if (!newStartsAt || !newEndsAt) {
      saveError = 'Podaj datę rozpoczęcia i zakończenia.';
      return;
    }
    if (newEndsAt < newStartsAt) {
      saveError = 'Data zakończenia nie może być wcześniejsza niż rozpoczęcia.';
      return;
    }

    saving = true;

    const { error } = await supabase
      .from('blocked_periods')
      .insert({
        company_id:  companyId,
        employee_id: newEmployeeId || null,
        starts_at:   newStartsAt,
        ends_at:     newEndsAt,
        reason:      newReason.trim() || null
      });

    if (error) {
      console.error(error);
      saveError = 'Nie udało się dodać blokady.';
      saving = false;
      return;
    }

    // Wyczyść formularz
    newStartsAt   = '';
    newEndsAt     = '';
    newReason     = '';
    newEmployeeId = '';
    saving        = false;
    await loadData();
  }

  // ── Usuń blokadę ──────────────────────────────────────────────────────────
  async function deleteBlock(id) {
    const { error } = await supabase
      .from('blocked_periods')
      .delete()
      .eq('id', id);

    if (error) {
      console.error(error);
      return;
    }

    deletingId = null;
    await loadData();
  }

  // ── Pomocnicze ───────────────────────────────────────────────────────────
  function scopeLabel(block) {
    if (block.employees?.name) return block.employees.name;
    return 'Cała firma';
  }

  function formatDate(dateStr) {
    return new Date(dateStr).toLocaleDateString('pl-PL');
  }
</script>

{#if loading}
  <p>Ładowanie blokad...</p>
{:else}

  <!-- Formularz dodawania -->
  <div class="form-block">
    <div class="form-row">
      <div class="field">
        <label for="bp-start">Od *</label>
        <input id="bp-start" type="date" bind:value={newStartsAt} />
      </div>
      <div class="field">
        <label for="bp-end">Do *</label>
        <input id="bp-end" type="date" bind:value={newEndsAt} />
      </div>
      <div class="field">
        <label for="bp-scope">Zakres</label>
        <select id="bp-scope" bind:value={newEmployeeId}>
          <option value="">Cała firma</option>
          {#each employees as emp}
            <option value={emp.id}>{emp.name}</option>
          {/each}
        </select>
      </div>
    </div>
    <div class="form-row">
      <div class="field field-wide">
        <label for="bp-reason">Powód (opcjonalnie)</label>
        <input id="bp-reason" type="text" placeholder="np. urlop, święto" bind:value={newReason} />
      </div>
      <button class="btn-add" on:click={addBlock} disabled={saving}>
        {saving ? 'Dodawanie...' : '+ Dodaj blokadę'}
      </button>
    </div>
    {#if saveError}
      <p class="error">{saveError}</p>
    {/if}
  </div>

  <!-- Lista blokad -->
  {#if blocks.length === 0}
    <p class="empty">Brak blokad.</p>
  {:else}
    <ul class="block-list">
      {#each blocks as block (block.id)}
        <li class="block-item">
          <div class="block-info">
            <span class="block-dates">
              {formatDate(block.starts_at)} — {formatDate(block.ends_at)}
            </span>
            <span class="block-scope">{scopeLabel(block)}</span>
            {#if block.reason}
              <span class="block-reason">{block.reason}</span>
            {/if}
          </div>

          <!-- Usuwanie z potwierdzeniem -->
          {#if deletingId === block.id}
            <div class="confirm-row">
              <span class="confirm-label">Usunąć?</span>
              <button class="btn-danger" on:click={() => deleteBlock(block.id)}>Tak</button>
              <button class="btn-ghost"  on:click={() => (deletingId = null)}>Nie</button>
            </div>
          {:else}
            <button class="btn-danger-ghost" on:click={() => (deletingId = block.id)}>
              🗑
            </button>
          {/if}
        </li>
      {/each}
    </ul>
  {/if}
{/if}

<style>
  /* Formularz */
  .form-block {
    display: flex;
    flex-direction: column;
    gap: 0.6rem;
    margin-bottom: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #eee;
  }

  .form-row {
    display: flex;
    gap: 0.6rem;
    flex-wrap: wrap;
    align-items: flex-end;
  }

  .field {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
  }

  .field-wide { flex: 1; min-width: 160px; }

  label {
    font-size: 0.78rem;
    font-weight: 600;
    color: #555;
  }

  input[type="date"],
  input[type="text"],
  select {
    padding: 0.4rem 0.6rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 0.82rem;
  }

  input:focus, select:focus {
    outline: none;
    border-color: #667eea;
  }

  /* Lista blokad */
  .block-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
  }

  .block-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
    padding: 0.6rem 0.75rem;
    border: 1px solid #e9ecef;
    border-radius: 6px;
    background: #fafafa;
  }

  .block-info {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    flex-wrap: wrap;
    flex: 1;
  }

  .block-dates { font-size: 0.85rem; font-weight: 600; color: #222; }
  .block-scope {
    font-size: 0.78rem;
    background: #e0f2fe;
    color: #0369a1;
    padding: 0.15rem 0.5rem;
    border-radius: 99px;
    font-weight: 600;
  }
  .block-reason { font-size: 0.78rem; color: #777; font-style: italic; }

  /* Potwierdzenie */
  .confirm-row { display: flex; align-items: center; gap: 0.4rem; }
  .confirm-label { font-size: 0.8rem; color: #dc2626; font-weight: 600; }

  /* Misc */
  .empty { font-size: 0.85rem; color: #999; margin: 0; }
  .error {
    font-size: 0.82rem;
    color: #c62828;
    background: #ffebee;
    border: 1px solid #ffcdd2;
    border-radius: 4px;
    padding: 0.4rem 0.6rem;
    margin: 0;
  }

  /* Przyciski */
  .btn-add {
    background: #667eea;
    color: white;
    border: none;
    padding: 0.45rem 0.9rem;
    border-radius: 4px;
    font-size: 0.82rem;
    font-weight: 600;
    cursor: pointer;
    white-space: nowrap;
    align-self: flex-end;
  }
  .btn-add:hover:not(:disabled) { background: #5a6fd6; }
  .btn-add:disabled { opacity: 0.7; cursor: not-allowed; }

  .btn-ghost {
    background: transparent;
    color: #555;
    border: 1px solid #ddd;
    padding: 0.3rem 0.65rem;
    border-radius: 4px;
    font-size: 0.78rem;
    cursor: pointer;
  }

  .btn-danger {
    background: #dc2626;
    color: white;
    border: none;
    padding: 0.3rem 0.65rem;
    border-radius: 4px;
    font-size: 0.78rem;
    font-weight: 600;
    cursor: pointer;
  }

  .btn-danger-ghost {
    background: transparent;
    color: #dc2626;
    border: 1px solid #fecaca;
    padding: 0.3rem 0.55rem;
    border-radius: 4px;
    font-size: 0.78rem;
    cursor: pointer;
  }
  .btn-danger-ghost:hover { background: #fef2f2; }
</style>