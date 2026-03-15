<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabaseClient';

  export let companyId;

  let bookings = [];
  let loading = true;

  // ── FILTRY I SORTOWANIE ───────────────────────────────────────────────────
  let filterStatus = 'all';        // 'all' | 'pending' | 'confirmed' | 'rejected'
  let filterRange  = 'upcoming';   // 'upcoming' | 'past' | 'all'
  let sortField    = 'booking_date';
  let sortAsc      = true;
 
  // Przeładuj dane przy każdej zmianie filtrów
  $: filterStatus, filterRange, sortField, sortAsc, loadBookings();
 
  async function loadBookings() {
    loading = true;
 
    const today = new Date().toISOString().split('T')[0]; // 'YYYY-MM-DD'
 
    // Buduj zapytanie
    let query = supabase
      .from('bookings')
      .select('*, employees ( name )')
      .eq('company_id', companyId);
 
    // Filtr statusu w zapytaniu
    if (filterStatus !== 'all') {
      query = query.eq('status', filterStatus);
    }
 
    // Filtr zakresu dat w zapytaniu
    if (filterRange === 'upcoming') {
      query = query.gte('booking_date', today);
    } else if (filterRange === 'past') {
      query = query.lt('booking_date', today);
    }
 
    // Sortowanie — 'employee' pochodzi z joina, Supabase nie obsługuje order() na relacji
    if (sortField !== 'employee') {
      query = query.order(sortField, { ascending: sortAsc });
    } else {
      query = query.order('booking_date', { ascending: true });
    }
 
    const { data, error } = await query;
 
    if (error) {
      console.error(error);
    } else {
      if (sortField === 'employee') {
        bookings = data.sort((a, b) => {
          const nameA = a.employees?.name ?? '';
          const nameB = b.employees?.name ?? '';
          if (nameA < nameB) return sortAsc ? -1 :  1;
          if (nameA > nameB) return sortAsc ?  1 : -1;
          return 0;
        });
      } else {
        bookings = data;
      }
    }
 
    loading = false;
  }

  onMount(loadBookings);

  // Funkcja updateStatus
  async function updateStatus(bookingId, status) {
    const { error } = await supabase
      .from('bookings')
      .update({ status })
      .eq('id', bookingId);
    if (error) {
      console.error(error);
    } else {
      await loadBookings();
    }
  }

</script>

{#if loading}
  <p>Ładowanie rezerwacji...</p>

{:else}
  <!-- Pasek filtrów -->
  <div class="filter-bar">
    <select bind:value={filterRange}>
      <option value="upcoming">Nadchodzące</option>
      <option value="past">Przeszłe</option>
      <option value="all">Wszystkie</option>
    </select>
 
    <select bind:value={filterStatus}>
      <option value="all">Wszystkie statusy</option>
      <option value="pending">Oczekujące</option>
      <option value="confirmed">Zatwierdzone</option>
      <option value="rejected">Odrzucone</option>
    </select>
  </div>
 
  {#if bookings.length === 0}
    <p>Brak rezerwacji spełniających kryteria.</p>
  {:else}
  <table class="booking-table">
    <thead>
      <tr>
        <!-- Klikalne nagłówki sortowania -->
        <th class="sortable" on:click={() => { sortField = 'booking_date'; sortAsc = sortField === 'booking_date' ? !sortAsc : true; }}>
          Data {sortField === 'booking_date' ? (sortAsc ? '↑' : '↓') : '↕'}
        </th>
        <th>Godzina</th>
        <th class="sortable" on:click={() => { sortField = 'customer_name'; sortAsc = sortField === 'customer_name' ? !sortAsc : true; }}>
          Klient {sortField === 'customer_name' ? (sortAsc ? '↑' : '↓') : '↕'}
        </th>
        <th>Email</th>
        <th>Telefon</th>
        <th class="sortable" on:click={() => { sortAsc = sortField === 'employee' ? !sortAsc : true; sortField = 'employee'; }}>
          Pracownik {sortField === 'employee' ? (sortAsc ? '↑' : '↓') : '↕'}
        </th>
        <th class="sortable" on:click={() => { sortField = 'status'; sortAsc = sortField === 'status' ? !sortAsc : true; }}>
          Status {sortField === 'status' ? (sortAsc ? '↑' : '↓') : '↕'}
        </th>
        <th>Akcje</th>
      </tr>
    </thead>

    <tbody>
      {#each bookings as booking}
        <tr>
          <td>{booking.booking_date}</td>
          <td>{booking.start_time}</td>
          <td>{booking.customer_name}</td>
          <td>{booking.customer_email}</td>
          <td>{booking.phone}</td>
          <td>{booking.employees?.name ?? 'Dowolny'}</td>
          <td>
            <span class="badge badge--{booking.status}">
              {#if booking.status === 'pending'}Oczekuje
              {:else if booking.status === 'confirmed'}Zatwierdzona
              {:else if booking.status === 'rejected'}Odrzucona
              {/if}
            </span>
          </td>
          <td>
            {#if booking.status === 'pending'}
              <button class="btn-confirm" on:click={() => 
              updateStatus(booking.id, 'confirmed')}>✓ Zatwierdź</button>
              <button class="btn-reject"  on:click={() => 
              updateStatus(booking.id, 'rejected')}>✕ Odrzuć</button>
            {/if}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
{/if}
{/if}
 

<style>
  .booking-table {
    width: 100%;
    border-collapse: collapse;
  }

  .filter-bar {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
    flex-wrap: wrap;
  }
  .filter-bar select {
    padding: 0.35rem 0.6rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 0.82rem;
    background: #fff;
    cursor: pointer;
  }
 
  th.sortable {
    cursor: pointer;
    user-select: none;
    white-space: nowrap;
  }
  th.sortable:hover { background: #f5f5f5; }

  th, td {
    padding: 0.5rem;
    border-bottom: 1px solid #ddd;
  }

  th {
    text-align: left;
  }

    .badge {
    display: inline-block;
    padding: 0.2rem 0.55rem;
    border-radius: 99px;
    font-size: 0.78rem;
    font-weight: 600;
  }
  .badge--pending   { background: #fef9c3; color: #854d0e; }
  .badge--confirmed { background: #dcfce7; color: #166534; }
  .badge--rejected  { background: #fee2e2; color: #991b1b; }
  .btn-confirm, .btn-reject {
    border: none;
    padding: 0.25rem 0.6rem;
    border-radius: 4px;
    font-size: 0.78rem;
    font-weight: 600;
    cursor: pointer;
    margin-right: 0.25rem;
  }
  .btn-confirm { background: #dcfce7; color: #166534; }
  .btn-confirm:hover { background: #bbf7d0; }
  .btn-reject  { background: #fee2e2; color: #991b1b; }
  .btn-reject:hover  { background: #fecaca; }
</style>