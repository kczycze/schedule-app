<script lang="ts">
  import type { PageData } from './$types';
  import Calendar from '$lib/components/client/Calendar.svelte';
  import TimeSlots from '$lib/components/client/TimeSlots.svelte';
  import BookingModal from '$lib/components/client/BookingModal.svelte';

  export let data: PageData;

  let selectedDate: Date | null = null;
  let selectedService: any = null;
  let selectedTime: string | null = null;
  let showBookingModal = false;

  // Reset time selection when date or service changes
  $: if (selectedDate || selectedService) {
    selectedTime = null;
  }

  function handleDateSelect(date: Date) {
    selectedDate = date;
  }

  function handleServiceSelect(service: any) {
    selectedService = service;
  }

  function handleTimeSelect(time: string) {
    selectedTime = time;
    showBookingModal = true;
  }

  function handleBookingSuccess() {
    // Reset state after successful booking
    selectedTime = null;
    showBookingModal = false;
  }

  function closeModal() {
    showBookingModal = false;
  }
</script>

<svelte:head>
  <title>{data.company.name} - Rezerwacja</title>
</svelte:head>

<div class="booking-page">
  <header class="header">
    <h1>{data.company.name}</h1>
    <p class="subtitle">Zarezerwuj wizytę online</p>
  </header>

  <main class="content">
    <!-- Services Section -->
    <section class="section services-section">
      <h2>Wybierz usługę</h2>
      {#if data.services.length === 0}
        <p class="empty-message">Brak dostępnych usług</p>
      {:else}
        <div class="services-grid">
          {#each data.services as service}
            <button
              class="service-card"
              class:selected={selectedService?.id === service.id}
              on:click={() => handleServiceSelect(service)}
            >
              <h3>{service.name}</h3>
              <div class="service-details">
                <span class="duration">{service.duration_minutes} min</span>
                <span class="price">{service.price} PLN</span>
              </div>
            </button>
          {/each}
        </div>
      {/if}
    </section>

    <!-- Calendar Section -->
    <section class="section calendar-section">
      <h2>Wybierz dzień</h2>
      <Calendar onDateSelect={handleDateSelect} {selectedDate} 
       workingDays={data.availability.working_days} 
       />
    </section>

    <!-- Time Slots Section -->
    {#if selectedService && selectedDate}
      <section class="section timeslots-section">
        <h2>Wybierz godzinę</h2>
        <TimeSlots
          {selectedDate}
          {selectedService}
          companyId={data.company.id}
          availability={data.availability}
          onTimeSelect={handleTimeSelect}
        />
      </section>
    {/if}
  </main>
</div>

<!-- Booking Modal -->
{#if showBookingModal && selectedService && selectedDate && selectedTime}
  <BookingModal
    {selectedService}
    {selectedDate}
    {selectedTime}
    companyId={data.company.id}
    companyName={data.company.name}
    bookingApproval={data.company.booking_approval} 
    onSuccess={handleBookingSuccess}
    onClose={closeModal}
  />
{/if}

<style>
  .booking-page {
    min-height: 100vh;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 2rem 1rem;
  }

  .header {
    text-align: center;
    color: white;
    margin-bottom: 3rem;
  }

  .header h1 {
    font-size: 2.5rem;
    margin: 0 0 0.5rem 0;
    font-weight: 700;
  }

  .subtitle {
    font-size: 1.1rem;
    opacity: 0.9;
    margin: 0;
  }

  .content {
    max-width: 1200px;
    margin: 0 auto;
  }

  .section {
    background: white;
    border-radius: 12px;
    padding: 2rem;
    margin-bottom: 2rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  }

  .section h2 {
    margin: 0 0 1.5rem 0;
    font-size: 1.5rem;
    color: #333;
  }

  .empty-message {
    color: #666;
    text-align: center;
    padding: 2rem;
  }

  /* Services Grid */
  .services-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 1rem;
  }

  .service-card {
    background: #f8f9fa;
    border: 2px solid #e9ecef;
    border-radius: 8px;
    padding: 1.5rem;
    cursor: pointer;
    transition: all 0.2s;
    text-align: left;
  }

  .service-card:hover {
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
  }

  .service-card.selected {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-color: #667eea;
    color: white;
  }

  .service-card h3 {
    margin: 0 0 1rem 0;
    font-size: 1.25rem;
  }

  .service-details {
    display: flex;
    justify-content: space-between;
    font-size: 0.95rem;
  }

  .service-card.selected .service-details {
    opacity: 0.95;
  }

  /* Responsive */
  @media (max-width: 768px) {
    .booking-page {
      padding: 1rem 0.5rem;
    }

    .header h1 {
      font-size: 2rem;
    }

    .section {
      padding: 1.5rem;
    }

    .services-grid {
      grid-template-columns: 1fr;
    }
  }
</style>