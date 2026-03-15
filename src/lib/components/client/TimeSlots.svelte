<script lang="ts">
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabaseClient';

  export let selectedDate: Date;
  export let selectedService: any;
  export let companyId: string;
  export let onTimeSelect: (time: string) => void;
  export let availability: {
    work_start:    string;
    work_end:      string;
    slot_duration: number;
  } = { work_start: '09:00', work_end: '17:00', slot_duration: 30 };

  let availableSlots: string[] = [];
  let loading = true;
  let error = '';

  $: if (selectedDate && selectedService) {
    loadAvailableSlots();
  }

  async function loadAvailableSlots() {
    loading = true;
    error = '';

    try {
      // Generate all possible time slots for the day
      const allSlots = generateAllTimeSlots();

      // Fetch existing bookings for the selected date
      const dateString = formatDateForDB(selectedDate);
      const { data: bookings, error: fetchError } = await supabase
        .from('bookings')
        .select('start_time, service_id, services(duration_minutes)')
        .eq('company_id', companyId)
        .eq('booking_date', dateString);

      if (fetchError) {
        throw fetchError;
      }

      // Filter out slots that conflict with existing bookings
      const bookedSlots = new Set<string>();
      
      if (bookings) {
        for (const booking of bookings) {
          const bookingStart = booking.start_time;
          const duration = booking.services?.[0]?.duration_minutes || 30;
          
          // Mark all slots that overlap with this booking
          const conflictingSlots = getConflictingSlots(bookingStart, duration, allSlots);
          conflictingSlots.forEach(slot => bookedSlots.add(slot));
        }
      }

      // Filter out booked slots and ensure service fits before closing time
      availableSlots = allSlots.filter(slot => {
        if (bookedSlots.has(slot)) return false;
        
        // Check if service duration fits before work end time
        const slotTime = parseTimeToMinutes(slot);
        const endTime = slotTime + selectedService.duration_minutes;
        const workEndTime = parseTimeToMinutes(availability.work_end);
        
        return endTime <= workEndTime;
      });

    } catch (err) {
      error = 'Nie udało się załadować dostępnych terminów';
      console.error('Error loading slots:', err);
    } finally {
      loading = false;
    }
  }

  function generateAllTimeSlots(): string[] {
    const slots: string[] = [];
    const startMinutes = parseTimeToMinutes(availability.work_start);
    const endMinutes   = parseTimeToMinutes(availability.work_end);
    const interval     = availability.slot_duration;

    for (let minutes = startMinutes; minutes < endMinutes; minutes += interval) {
      const hours = Math.floor(minutes / 60);
      const mins = minutes % 60;
      const timeString = `${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}`;
      slots.push(timeString);
    }

    return slots;
  }

  function getConflictingSlots(startTime: string, durationMinutes: number, allSlots: string[]): string[] {
    const startMinutes = parseTimeToMinutes(startTime);
    const endMinutes = startMinutes + durationMinutes;
    
    return allSlots.filter(slot => {
      const slotMinutes = parseTimeToMinutes(slot);
      // A slot conflicts if it starts within the booking's time range
      return slotMinutes >= startMinutes && slotMinutes < endMinutes;
    });
  }

  function parseTimeToMinutes(time: string): number {
    const [hours, minutes] = time.split(':').map(Number);
    return hours * 60 + minutes;
  }

  function formatDateForDB(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function handleSlotClick(slot: string) {
    onTimeSelect(slot);
  }
</script>

<div class="timeslots">
  {#if loading}
    <div class="loading">
      <div class="spinner"></div>
      <p>Ładowanie dostępnych terminów...</p>
    </div>
  {:else if error}
    <div class="error-message">
      <p>{error}</p>
      <button on:click={loadAvailableSlots}>Spróbuj ponownie</button>
    </div>
  {:else if availableSlots.length === 0}
    <div class="empty-message">
      <p>Brak wolnych terminów w tym dniu</p>
      <p class="hint">Spróbuj wybrać inny dzień</p>
    </div>
  {:else}
    <div class="slots-grid">
      {#each availableSlots as slot}
        <button class="slot-button" on:click={() => handleSlotClick(slot)}>
          {slot}
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .timeslots {
    min-height: 200px;
  }

  .loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 3rem;
    color: #666;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #667eea;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-bottom: 1rem;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  .error-message {
    text-align: center;
    padding: 2rem;
    color: #d32f2f;
  }

  .error-message button {
    margin-top: 1rem;
    padding: 0.5rem 1.5rem;
    background: #667eea;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
  }

  .empty-message {
    text-align: center;
    padding: 3rem 1rem;
    color: #666;
  }

  .empty-message p {
    margin: 0.5rem 0;
  }

  .hint {
    font-size: 0.9rem;
    color: #999;
  }

  .slots-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
    gap: 0.75rem;
  }

  .slot-button {
    padding: 1rem;
    background: white;
    border: 2px solid #e9ecef;
    border-radius: 8px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .slot-button:hover {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-color: #667eea;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.2);
  }

  @media (max-width: 768px) {
    .slots-grid {
      grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
      gap: 0.5rem;
    }

    .slot-button {
      padding: 0.75rem;
      font-size: 0.9rem;
    }
  }
</style>