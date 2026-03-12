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
</style>