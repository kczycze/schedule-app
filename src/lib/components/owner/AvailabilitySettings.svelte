<script>
  import { supabase } from '$lib/supabaseClient';
  import { onMount } from 'svelte';

  export let companyId;

  // ── Stan ─────────────────────────────────────────────────────────────────
  let loading  = true;
  let saving   = false;
  let saved    = false;
  let saveError = '';

  // Wartości formularza
  let workStart    = '09:00';
  let workEnd      = '17:00';
  let slotDuration = 30;
  let workingDays  = [1, 2, 3, 4, 5]; // domyślnie pon–pt

  const DAY_LABELS = [
    { value: 1, label: 'Pon' },
    { value: 2, label: 'Wt'  },
    { value: 3, label: 'Śr'  },
    { value: 4, label: 'Czw' },
    { value: 5, label: 'Pt'  },
    { value: 6, label: 'Sob' },
    { value: 7, label: 'Ndz' },
  ];

  const SLOT_OPTIONS = [15, 30, 45, 60];

  // ── Ładowanie ────────────────────────────────────────────────────────────
  async function loadSettings() {
    loading = true;

    const { data, error } = await supabase
      .from('availability_settings')
      .select('working_days, work_start, work_end, slot_duration')
      .eq('company_id', companyId)
      .single();

    if (error) {
      console.error('Błąd ładowania ustawień:', error);
    } else if (data) {
      workingDays  = data.working_days  ?? [1, 2, 3, 4, 5];
      workStart    = data.work_start    ?? '09:00';
      workEnd      = data.work_end      ?? '17:00';
      slotDuration = data.slot_duration ?? 30;
    }

    loading = false;
  }

  onMount(loadSettings);

  // ── Zapis ────────────────────────────────────────────────────────────────
  async function saveSettings() {
    saveError = '';

    // Walidacja
    if (workingDays.length === 0) {
      saveError = 'Wybierz co najmniej jeden dzień pracy.';
      return;
    }
    if (workStart >= workEnd) {
      saveError = 'Godzina zakończenia musi być późniejsza niż rozpoczęcia.';
      return;
    }

    saving = true;

    const { error } = await supabase
      .from('availability_settings')
      .update({
        working_days:  workingDays,
        work_start:    workStart,
        work_end:      workEnd,
        slot_duration: slotDuration,
      })
      .eq('company_id', companyId);

    if (error) {
      console.error('Błąd zapisu:', error);
      saveError = 'Nie udało się zapisać ustawień.';
      saving = false;
      return;
    }

    saving = false;
    saved  = true;
    setTimeout(() => (saved = false), 2500);
  }

  // ── Obsługa checkboxów dni ────────────────────────────────────────────────
  function toggleDay(value) {
    workingDays = workingDays.includes(value)
      ? workingDays.filter(d => d !== value)
      : [...workingDays, value].sort((a, b) => a - b);
  }
</script>

{#if loading}
  <p>Ładowanie ustawień...</p>
{:else}
  <div class="availability">

    <!-- Dni pracy -->
    <div class="field-group">
      <p class="field-label">Dni pracy</p>
      <div class="days-row">
        {#each DAY_LABELS as day}
          <button
            type="button"
            class="day-btn"
            class:day-active={workingDays.includes(day.value)}
            on:click={() => toggleDay(day.value)}
          >
            {day.label}
          </button>
        {/each}
      </div>
    </div>

    <!-- Godziny pracy -->
    <div class="hours-row">
      <div class="field-group">
        <label class="field-label" for="work-start">Godzina rozpoczęcia</label>
        <input
          id="work-start"
          type="time"
          bind:value={workStart}
        />
      </div>

      <div class="field-group">
        <label class="field-label" for="work-end">Godzina zakończenia</label>
        <input
          id="work-end"
          type="time"
          bind:value={workEnd}
        />
      </div>
    </div>

    <!-- Długość slotu -->
    <div class="field-group">
      <p class="field-label">Długość slotu rezerwacji</p>
      <div class="slot-row">
        {#each SLOT_OPTIONS as mins}
          <button
            type="button"
            class="slot-btn"
            class:slot-active={slotDuration === mins}
            on:click={() => (slotDuration = mins)}
          >
            {mins} min
          </button>
        {/each}
      </div>
    </div>

    <!-- Błąd walidacji -->
    {#if saveError}
      <p class="error">{saveError}</p>
    {/if}

    <button class="btn-save" on:click={saveSettings} disabled={saving}>
      {#if saving}Zapisywanie...{:else if saved}✓ Zapisano{:else}Zapisz ustawienia{/if}
    </button>

  </div>
{/if}

<style>
  .availability {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
  }

  .field-group {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .field-label {
    font-size: 0.85rem;
    font-weight: 600;
    color: #333;
    margin: 0;
  }

  /* Dni tygodnia */
  .days-row {
    display: flex;
    gap: 0.4rem;
    flex-wrap: wrap;
  }

  .day-btn {
    padding: 0.4rem 0.7rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    background: #fff;
    font-size: 0.82rem;
    font-weight: 600;
    cursor: pointer;
    color: #555;
    transition: all 0.15s;
  }
  .day-btn:hover   { border-color: #667eea; color: #667eea; }
  .day-active      { border-color: #667eea; background: #f0f1ff; color: #667eea; }

  /* Godziny */
  .hours-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
  }

  input[type="time"] {
    padding: 0.45rem 0.6rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 0.9rem;
    color: #333;
    transition: border-color 0.15s;
  }
  input[type="time"]:focus {
    outline: none;
    border-color: #667eea;
  }

  /* Slot */
  .slot-row {
    display: flex;
    gap: 0.4rem;
  }

  .slot-btn {
    padding: 0.4rem 0.8rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    background: #fff;
    font-size: 0.82rem;
    font-weight: 600;
    cursor: pointer;
    color: #555;
    transition: all 0.15s;
  }
  .slot-btn:hover { border-color: #667eea; color: #667eea; }
  .slot-active    { border-color: #667eea; background: #f0f1ff; color: #667eea; }

  /* Zapis */
  .btn-save {
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

  .error {
    font-size: 0.82rem;
    color: #c62828;
    background: #ffebee;
    border: 1px solid #ffcdd2;
    border-radius: 6px;
    padding: 0.5rem 0.75rem;
    margin: 0;
  }
</style>