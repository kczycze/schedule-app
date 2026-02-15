<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabaseClient';

  export let companyId;

  let services = [];
  let showForm = false;
  let newService = {
    name: '',
    duration_minutes: 30,
    price: 0
  };

  onMount(async () => {
    await loadServices();
  });

  async function loadServices() {
    const { data } = await supabase
      .from('services')
      .select('*')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });

    services = data || [];
  }

  async function addService() {
    const { error } = await supabase
      .from('services')
      .insert({
        company_id: companyId,
        ...newService
      });

    if (!error) {
      await loadServices();
      showForm = false;
      newService = { name: '', duration_minutes: 30, price: 0 };
    }
  }
</script>

<div class="service-list">
  <button on:click={() => showForm = !showForm}>
    {showForm ? 'Anuluj' : '+ Dodaj usługę'}
  </button>

{#if showForm}
  <form on:submit|preventDefault={addService}>

    <label for="service-name" class="visually-hidden">
      Nazwa usługi
    </label>

    <input 
      id="service-name"
      type="text"
      bind:value={newService.name}
      placeholder="Nazwa usługi"
      required
    />

    <div class="form-group">
      <label for="service-duration">Czas trwania</label>
      <div class="input-row">
        <input 
          id="service-duration"
          type="number" 
          bind:value={newService.duration_minutes}
          min="5"
          step="5"
          required
        />
        <span>min</span>
      </div>
    </div>

    <div class="form-group">
      <label for="service-price">Cena</label>
      <div class="input-row">
        <input 
          id="service-price"
          type="number" 
          bind:value={newService.price}
          step="0.01"
          min="0"
        />
        <span>PLN</span>
      </div>
    </div>

    <button type="submit">Zapisz</button>

  </form>
{/if}


  <ul>
    {#each services as service}
      <li>
        <strong>{service.name}</strong>
        <span>{service.duration_minutes} min | {service.price} PLN</span>
      </li>
    {/each}
  </ul>
</div>

<style>
  .service-list button {
    margin-bottom: 1rem;
    padding: 0.5rem 1rem;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  form {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    margin-bottom: 1rem;
    padding: 1rem;
    background-color: #f9f9f9;
    border-radius: 4px;
  }

  input {
    padding: 0.5rem;
    border: 1px solid #ccc;
    border-radius: 4px;
  }

  ul {
    list-style: none;
    padding: 0;
  }

  li {
    display: flex;
    justify-content: space-between;
    padding: 0.75rem;
    margin-bottom: 0.5rem;
    background-color: #f5f5f5;
    border-radius: 4px;
  }

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.input-row {
  display: flex;
  align-items: center;
  gap: 6px;
}


</style>