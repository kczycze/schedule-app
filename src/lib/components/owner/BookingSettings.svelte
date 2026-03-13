<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  export let companyId;

  let bookingApproval = 'auto';
  let loading = true;
  let saving = false;
  let saved = false;

  async function loadSettings() {
    loading = true;
    const { data } = await supabase
      .from('companies')
      .select('booking_approval')
      .eq('id', companyId)
      .single();

    if (data) bookingApproval = data.booking_approval;
    loading = false;
  }

async function saveSettings() {
    saving = true;
    saved = false;

    const { error } = await supabase
      .from('companies')
      .update({ booking_approval: bookingApproval })
      .eq('id', companyId);

    if (error) {
      console.error('Błąd zapisu:', error);
      saving = false;
      return;
    }

    saving = false;
    saved = true;
    setTimeout(() => (saved = false), 2500);
  }

  onMount(loadSettings);
</script>

{#if loading}
  <p>Ładowanie ustawień...</p>
{:else}
  <div class="settings-group">
    <p class="settings-desc">Wybierz czy nowe rezerwacje mają być zatwierdzane automatycznie, czy ręcznie.</p>

    <label class="option" class:active={bookingApproval === 'auto'}>
      <input type="radio" bind:group={bookingApproval} value="auto" />
      <div class="option-body">
        <strong>Automatycznie</strong>
        <span>Rezerwacja od razu otrzymuje status "Zatwierdzona"</span>
      </div>
    </label>

    <label class="option" class:active={bookingApproval === 'manual'}>
      <input type="radio" bind:group={bookingApproval} value="manual" />
      <div class="option-body">
        <strong>Ręcznie</strong>
        <span>Rezerwacja czeka na Twoje zatwierdzenie w dashboardzie</span>
      </div>
    </label>

    <button class="btn-save" on:click={saveSettings} disabled={saving}>
      {#if saving}Zapisywanie...{:else if saved}✓ Zapisano{:else}Zapisz ustawienie{/if}
    </button>
  </div>
{/if}

<style>
  .settings-desc {
    font-size: 0.85rem;
    color: #666;
    margin: 0 0 0.75rem;
  }

  .settings-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .option {
    display: flex;
    align-items: flex-start;
    gap: 0.75rem;
    padding: 0.75rem;
    border: 2px solid #e9ecef;
    border-radius: 8px;
    cursor: pointer;
    transition: border-color 0.15s;
  }
  .option:hover  { border-color: #667eea; }
  .option.active { border-color: #667eea; background: #f0f1ff; }

  .option input[type="radio"] {
    margin-top: 0.2rem;
    accent-color: #667eea;
    flex-shrink: 0;
  }

  .option-body {
    display: flex;
    flex-direction: column;
    gap: 0.15rem;
  }
  .option-body strong { font-size: 0.9rem; color: #222; }
  .option-body span   { font-size: 0.78rem; color: #777; }

  .btn-save {
    margin-top: 0.25rem;
    padding: 0.45rem 1rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 6px;
    font-size: 0.85rem;
    font-weight: 600;
    cursor: pointer;
    align-self: flex-start;
    transition: background 0.15s;
  }
  .btn-save:hover:not(:disabled) { background: #5a6fd6; }
  .btn-save:disabled { opacity: 0.7; cursor: not-allowed; }
</style>