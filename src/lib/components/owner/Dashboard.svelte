<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabaseClient';
  import { user } from '$lib/stores';
  import { goto } from '$app/navigation';
  import ServiceList from './ServiceList.svelte';
  import BookingList from './BookingList.svelte';
  import EmployeeList from './EmployeeList.svelte';

  let company = null;
  let loading = true;

  // ✅ Guard – jeśli user null → wróć na stronę główną
  $: if ($user === null && !loading) {
  goto('/');
}


let companyLoadedFor = null;

$: if ($user && companyLoadedFor !== $user.id) {
  loadCompany();
}

async function loadCompany() {
  loading = true;

  const { data, error } = await supabase
    .from('companies')
    .select('*')
    .eq('owner_id', $user.id)
    .maybeSingle();

  if (!error) {
    company = data;
    companyLoadedFor = $user.id; // 🔥 zapamiętujemy dla kogo załadowano
  } else {
    console.error(error);
  }

  loading = false;
}

  async function handleLogout() {
    await supabase.auth.signOut();
    goto('/'); // zamiast window.location
  }
</script>

<div class="dashboard">
  <header>
    <h1>Panel właściciela</h1>
    {#if company}
      <p>Firma: {company.name}</p>
      <p>Publiczny link: <a href="/{company.slug}" target="_blank">/{company.slug}</a></p>
    {/if}
    <button on:click={handleLogout}>Wyloguj</button>
  </header>

  {#if loading}
    <p>Ładowanie...</p>
  {:else if company}
    <div class="dashboard-content">
      <section>
        <h2>Usługi</h2>
        <ServiceList companyId={company.id} />
      </section>

      <section>
        <h2>Rezerwacje</h2>
        <BookingList companyId={company.id} />
      </section>
      
      <section>
        <h2>Pracownicy</h2>
        <EmployeeList companyId={company.id} />
      </section>

    </div>
  {:else}
    <p>Nie znaleziono firmy.</p>
  {/if}
</div>

<style>
  .dashboard {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }

  header {
    margin-bottom: 2rem;
    padding-bottom: 1rem;
    border-bottom: 2px solid #eee;
  }

  header button {
    margin-top: 1rem;
    padding: 0.5rem 1rem;
    background-color: #f44336;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .dashboard-content {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
  }

  section {
    padding: 1rem;
    border: 1px solid #ddd;
    border-radius: 8px;
  }

  @media (max-width: 768px) {
    .dashboard-content {
      grid-template-columns: 1fr;
    }
  }
</style>