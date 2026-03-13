<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabaseClient';

  export let companyId;

  let bookings = [];
  let loading = true;

  async function loadBookings() {
    const { data, error } = await supabase
      .from('bookings')
      .select('*, employees ( name )')
      .eq('company_id', companyId)
      .order('booking_date', { ascending: true });

    if (error) {
      console.error(error);
    } else {
      bookings = data;
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

{:else if bookings.length === 0}
  <p>Brak rezerwacji.</p>

{:else}
  <table class="booking-table">
    <thead>
      <tr>
        <th>Data</th>
        <th>Godzina</th>
        <th>Klient</th>
        <th>Email</th>
        <th>Telefon</th>
        <th>Pracownik</th>
        <th>Status</th>
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
 

<style>
  .booking-table {
    width: 100%;
    border-collapse: collapse;
  }

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