<script lang="ts">
  import { supabase } from '$lib/supabaseClient';

  export let selectedService: any;
  export let selectedDate: Date;
  export let selectedTime: string;
  export let companyId: string;
  export let companyName: string;
  export let onSuccess: () => void;
  export let onClose: () => void;

  let customerName = '';
  let customerEmail = '';
  let loading = false;
  let error = '';
  let success = false;

  // Form validation states
  let emailError = '';

  $: formattedDate = selectedDate.toLocaleDateString('pl-PL', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  function validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email) {
      emailError = 'Email jest wymagany';
      return false;
    }
    if (!emailRegex.test(email)) {
      emailError = 'Nieprawidłowy format email';
      return false;
    }
    emailError = '';
    return true;
  }

  async function handleSubmit() {
    error = '';
    
    // Validate all fields
    const isEmailValid = validateEmail(customerEmail);

    if (!customerName.trim()) {
      error = 'Imię i nazwisko są wymagane';
      return;
    }

    if (!isEmailValid) {
      return;
    }

    loading = true;

    try {
      // Format date for database
      const dateString = formatDateForDB(selectedDate);

      // Insert booking into bookings table
      const { error: insertError } = await supabase
        .from('bookings')
        .insert({
          company_id: companyId,
          service_id: selectedService.id,
          booking_date: dateString,
          start_time: selectedTime,
          customer_name: customerName.trim(),
          customer_email: customerEmail.trim(),
          status: 'pending'
        });

      if (insertError) {
        throw insertError;
      }

      // Show success message
      success = true;

      // Close modal after delay
      setTimeout(() => {
        onSuccess();
      }, 2000);

    } catch (err: any) {
      error = err.message || 'Wystąpił błąd podczas rezerwacji';
      console.error('Booking error:', err);
    } finally {
      loading = false;
    }
  }

  function formatDateForDB(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  function handleBackdropClick(event: MouseEvent) {
    if (event.target === event.currentTarget) {
      onClose();
    }
  }

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      onClose();
    }
  }
</script>

<svelte:window on:keydown={handleKeydown} />

<div
  class="modal-backdrop"
  role="presentation"
  on:click={handleBackdropClick}
>
  <div
    class="modal"
    role="dialog"
    aria-modal="true"
    aria-labelledby="modal-title"
    tabindex="0"
    on:click|stopPropagation
    on:keydown={handleKeydown}
  >
    <div class="modal-header">
      <h2 id="modal-title">Potwierdź rezerwację</h2>
      <button
        class="close-button"
        on:click={onClose}
        aria-label="Zamknij"
      >
        ×
      </button>
    </div>

    {#if success}
      <div class="success-message">
        <div class="success-icon">✓</div>
        <h3>Rezerwacja potwierdzona!</h3>
        <p>Potwierdzenie zostało wysłane na podany adres email.</p>
      </div>
    {:else}
      <div class="modal-body">
        <!-- Booking Summary -->
        <div class="booking-summary">
          <h3>Szczegóły rezerwacji</h3>
          <div class="summary-item">
            <span class="label">Firma:</span>
            <span class="value">{companyName}</span>
          </div>
          <div class="summary-item">
            <span class="label">Usługa:</span>
            <span class="value">{selectedService.name}</span>
          </div>
          <div class="summary-item">
            <span class="label">Data:</span>
            <span class="value">{formattedDate}</span>
          </div>
          <div class="summary-item">
            <span class="label">Godzina:</span>
            <span class="value">{selectedTime}</span>
          </div>
          <div class="summary-item">
            <span class="label">Czas trwania:</span>
            <span class="value">{selectedService.duration_minutes} min</span>
          </div>
          <div class="summary-item price">
            <span class="label">Cena:</span>
            <span class="value">{selectedService.price} PLN</span>
          </div>
        </div>

        <!-- Form -->
        <form on:submit|preventDefault={handleSubmit}>
          <div class="form-group">
            <label for="customerName">Imię i nazwisko *</label>
            <input
              id="customerName"
              type="text"
              bind:value={customerName}
              placeholder="Jan Kowalski"
              required
              disabled={loading}
            />
          </div>

          <div class="form-group">
            <label for="customerEmail">Email *</label>
            <input
              id="customerEmail"
              type="email"
              bind:value={customerEmail}
              on:blur={() => validateEmail(customerEmail)}
              placeholder="jan.kowalski@example.com"
              required
              disabled={loading}
            />
            {#if emailError}
              <span class="field-error">{emailError}</span>
            {/if}
          </div>

          {#if error}
            <div class="error-message">
              {error}
            </div>
          {/if}

          <div class="form-actions">
            <button type="button" class="cancel-button" on:click={onClose} disabled={loading}>
              Anuluj
            </button>
            <button type="submit" class="submit-button" disabled={loading}>
              {loading ? 'Rezerwacja...' : 'Zarezerwuj wizytę'}
            </button>
          </div>
        </form>
      </div>
    {/if}
  </div>
</div>

<style>
  .modal-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.6);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: 1rem;
    backdrop-filter: blur(4px);
  }

  .modal {
    background: white;
    border-radius: 12px;
    width: 100%;
    max-width: 600px;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
    animation: modalSlideIn 0.3s ease-out;
  }

  @keyframes modalSlideIn {
    from {
      opacity: 0;
      transform: translateY(-50px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.5rem 2rem;
    border-bottom: 1px solid #e9ecef;
  }

  .modal-header h2 {
    margin: 0;
    font-size: 1.5rem;
    color: #333;
  }

  .close-button {
    background: none;
    border: none;
    font-size: 2rem;
    line-height: 1;
    cursor: pointer;
    color: #999;
    padding: 0;
    width: 32px;
    height: 32px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 4px;
    transition: all 0.2s;
  }

  .close-button:hover {
    background: #f8f9fa;
    color: #333;
  }

  .modal-body {
    padding: 2rem;
  }

  .booking-summary {
    background: #f8f9fa;
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;
  }

  .booking-summary h3 {
    margin: 0 0 1rem 0;
    font-size: 1.1rem;
    color: #333;
  }

  .summary-item {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
    border-bottom: 1px solid #e9ecef;
  }

  .summary-item:last-child {
    border-bottom: none;
  }

  .summary-item.price {
    margin-top: 0.5rem;
    padding-top: 1rem;
    border-top: 2px solid #667eea;
    font-weight: 600;
    font-size: 1.1rem;
  }

  .label {
    color: #666;
  }

  .value {
    color: #333;
    font-weight: 500;
  }

  .form-group {
    margin-bottom: 1.5rem;
  }

  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
    color: #333;
  }

  input {
    width: 100%;
    padding: 0.75rem;
    border: 2px solid #e9ecef;
    border-radius: 6px;
    font-size: 1rem;
    transition: all 0.2s;
  }

  input:focus {
    outline: none;
    border-color: #667eea;
  }

  input:disabled {
    background: #f8f9fa;
    cursor: not-allowed;
  }

  .field-error {
    display: block;
    color: #d32f2f;
    font-size: 0.85rem;
    margin-top: 0.25rem;
  }

  .error-message {
    background: #ffebee;
    color: #c62828;
    padding: 1rem;
    border-radius: 6px;
    margin-bottom: 1rem;
  }

  .success-message {
    padding: 3rem 2rem;
    text-align: center;
  }

  .success-icon {
    width: 80px;
    height: 80px;
    margin: 0 auto 1.5rem;
    background: linear-gradient(135deg, #4caf50 0%, #66bb6a 100%);
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 3rem;
    animation: successPop 0.5s ease-out;
  }

  @keyframes successPop {
    0% {
      transform: scale(0);
    }
    50% {
      transform: scale(1.1);
    }
    100% {
      transform: scale(1);
    }
  }

  .success-message h3 {
    color: #4caf50;
    margin: 0 0 0.5rem 0;
  }

  .success-message p {
    color: #666;
    margin: 0;
  }

  .form-actions {
    display: flex;
    gap: 1rem;
    margin-top: 2rem;
  }

  .cancel-button,
  .submit-button {
    flex: 1;
    padding: 0.875rem 1.5rem;
    border: none;
    border-radius: 6px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
  }

  .cancel-button {
    background: #f8f9fa;
    color: #666;
    border: 1px solid #e9ecef;
  }

  .cancel-button:hover:not(:disabled) {
    background: #e9ecef;
  }

  .submit-button {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
  }

  .submit-button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }

  .cancel-button:disabled,
  .submit-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  @media (max-width: 768px) {
    .modal {
      margin: 0;
      border-radius: 12px 12px 0 0;
      max-height: 95vh;
    }

    .modal-header,
    .modal-body {
      padding: 1.5rem;
    }

    .form-actions {
      flex-direction: column;
    }
  }
</style>