<script>
  import { supabase } from '$lib/supabaseClient';

  export let companyId;
  export let selectedDate;
  export let selectedTime;
  export let services = [];

  let customerName = '';
  let customerEmail = '';
  let selectedServiceId = '';
  let success = false;
  let error = '';

  async function handleBooking() {
    error = '';
    
    if (!selectedServiceId || !selectedDate || !selectedTime) {
      error = 'Proszę wybrać usługę, datę i godzinę.';
      return;
    }

    const { error: bookingError } = await supabase
      .from('bookings')
      .insert({
        company_id: companyId,
        service_id: selectedServiceId,
        booking_date: selectedDate,
        start_time: selectedTime,
        customer_name: customerName,
        customer_email: customerEmail,
        status: 'pending'
      });

    if (bookingError) {
      error = 'Błąd rezerwacji: ' + bookingError.message;
    } else {
      success = true;
      // Reset form
      customerName = '';
      customerEmail = '';
      selectedServiceId = '';
    }
  }
</script>

<div class="booking-form">
  <h3>Formularz rezerwacji</h3>

  {#if success}
    <div class="success">
      Rezerwacja została pomyślnie zapisana! Potwierdzenie wyślemy na email.
    </div>
  {/if}

  {#if error}
    <div class="error">{error}</div>
  {/if}

  <form on:submit|preventDefault={handleBooking}>
    <div class="form-group">
      <label>Wybierz usługę</label>
      <select bind:value={selectedServiceId} required>
        <option value="">-- Wybierz --</option>
        {#each services as service}
          <option value={service.id}>
            {service.name} ({service.duration_minutes} min, {service.price} PLN)
          </option>
        {/each}
      </select>
    </div>

    <div class="form-group">
      <label>Data i godzina</label>
      <p><strong>{selectedDate} o {selectedTime}</strong></p>
    </div>

    <div class="form-group">
      <label>Imię i nazwisko</label>
      <input 
        type="text" 
        bind:value={customerName}
        placeholder="Jan Kowalski"
        required
      />
    </div>

    <div class="form-group">
      <label>Email</label>
      <input 
        type="email" 
        bind:value={customerEmail}
        placeholder="jan@example.com"
        required
      />
    </div>

    <button type="submit">Zarezerwuj</button>
  </form>
</div>

<style>
  .booking-form {
    max-width: 500px;
    margin: 2rem auto;
    padding: 2rem;
    border: 1px solid #ddd;
    border-radius: 8px;
  }

  .form-group {
    margin-bottom: 1rem;
  }

  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
  }

  input, select {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid #ccc;
    border-radius: 4px;
  }

  button {
    width: 100%;
    padding: 0.75rem;
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
  }

  .success {
    padding: 1rem;
    margin-bottom: 1rem;
    background-color: #d4edda;
    color: #155724;
    border-radius: 4px;
  }

  .error {
    padding: 1rem;
    margin-bottom: 1rem;
    background-color: #f8d7da;
    color: #721c24;
    border-radius: 4px;
  }
</style>