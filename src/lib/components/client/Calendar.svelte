<script lang="ts">
  export let onDateSelect: (date: Date) => void;
  export let selectedDate: Date | null = null;
  export let workingDays: number[] = [1, 2, 3, 4, 5, 6, 7];

  let currentMonth = new Date();
  let today = new Date();
  today.setHours(0, 0, 0, 0);

  // Get calendar data for current month
  $: calendarDays = generateCalendarDays(currentMonth);
  $: monthName = currentMonth.toLocaleDateString('pl-PL', { month: 'long', year: 'numeric' });

  interface CalendarDay {
    date: Date;
    isCurrentMonth: boolean;
    isToday: boolean;
    isPast: boolean;
    isSelected: boolean;
    isWorkingDay: boolean; 
  }

  function generateCalendarDays(month: Date): CalendarDay[] {
    const year = month.getFullYear();
    const monthIndex = month.getMonth();

    // First day of the month
    const firstDay = new Date(year, monthIndex, 1);
    
    // Last day of the month
    const lastDay = new Date(year, monthIndex + 1, 0);

    // Get day of week for first day (0 = Sunday, 1 = Monday, etc.)
    // We want Monday = 0, so adjust
    let firstDayOfWeek = firstDay.getDay() - 1;
    if (firstDayOfWeek === -1) firstDayOfWeek = 6; // Sunday becomes 6

    const days: CalendarDay[] = [];

    // Add days from previous month to fill the first week
    const prevMonthLastDay = new Date(year, monthIndex, 0).getDate();
    for (let i = firstDayOfWeek - 1; i >= 0; i--) {
      const date = new Date(year, monthIndex - 1, prevMonthLastDay - i);
      days.push({
        date,
        isCurrentMonth: false,
        isToday: isSameDay(date, today),
        isPast: date < today,
        isSelected: selectedDate ? isSameDay(date, selectedDate) : false,
        isWorkingDay: isWorkingDay(date)
      });
    }

    // Add all days of current month
    for (let day = 1; day <= lastDay.getDate(); day++) {
      const date = new Date(year, monthIndex, day);
      days.push({
        date,
        isCurrentMonth: true,
        isToday: isSameDay(date, today),
        isPast: date < today,
        isSelected: selectedDate ? isSameDay(date, selectedDate) : false,
        isWorkingDay: isWorkingDay(date)
      });
    }

    // Add days from next month to complete the last week
    const remainingDays = 42 - days.length; // 6 rows × 7 days
    for (let day = 1; day <= remainingDays; day++) {
      const date = new Date(year, monthIndex + 1, day);
      days.push({
        date,
        isCurrentMonth: false,
        isToday: isSameDay(date, today),
        isPast: date < today,
        isSelected: selectedDate ? isSameDay(date, selectedDate) : false,
        isWorkingDay: isWorkingDay(date)
      });
    }

    return days;
  }

  function isSameDay(date1: Date, date2: Date): boolean {
    return (
      date1.getFullYear() === date2.getFullYear() &&
      date1.getMonth() === date2.getMonth() &&
      date1.getDate() === date2.getDate()
    );
  }

  function isWorkingDay(date: Date): boolean {
    const jsDay  = date.getDay();
    const isoDay = jsDay === 0 ? 7 : jsDay;
    return workingDays.includes(isoDay);
  }

  function previousMonth() {
    currentMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1, 1);
  }

  function nextMonth() {
    currentMonth = new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1, 1);
  }

  function selectDay(day: CalendarDay) {
    if (day.isPast || !day.isCurrentMonth || !day.isWorkingDay) return;
    onDateSelect(day.date);
  }

  const weekDays = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Ndz'];
</script>

<div class="calendar">
  <!-- Month Navigation -->
  <div class="calendar-header">
    <button class="nav-button" on:click={previousMonth} aria-label="Poprzedni miesiąc">
      ←
    </button>
    <h3 class="month-title">{monthName}</h3>
    <button class="nav-button" on:click={nextMonth} aria-label="Następny miesiąc">
      →
    </button>
  </div>

  <!-- Weekday Headers -->
  <div class="weekdays">
    {#each weekDays as day}
      <div class="weekday">{day}</div>
    {/each}
  </div>

  <!-- Calendar Grid -->
  <div class="calendar-grid">
    {#each calendarDays as day}
      <button
        class="calendar-day"
        class:other-month={!day.isCurrentMonth}
        class:today={day.isToday}
        class:past={day.isPast}
        class:selected={day.isSelected}
        class:off-day={!day.isWorkingDay}
        disabled={day.isPast || !day.isCurrentMonth || !day.isWorkingDay}
        on:click={() => selectDay(day)}
      >
        {day.date.getDate()}
      </button>
    {/each}
  </div>
</div>

<style>
  .calendar {
    width: 100%;
  }

  .calendar-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
  }

  .month-title {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
    color: #333;
    text-transform: capitalize;
  }

  .nav-button {
    background: #f8f9fa;
    border: 1px solid #e9ecef;
    border-radius: 6px;
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    font-size: 1.25rem;
    transition: all 0.2s;
  }

  .nav-button:hover {
    background: #e9ecef;
    border-color: #667eea;
  }

  .weekdays {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 0.5rem;
    margin-bottom: 0.5rem;
  }

  .weekday {
    text-align: center;
    font-weight: 600;
    font-size: 0.85rem;
    color: #666;
    padding: 0.5rem;
  }

  .calendar-grid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 0.5rem;
  }

  .calendar-day {
    aspect-ratio: 1;
    border: 1px solid #e9ecef;
    background: white;
    border-radius: 8px;
    cursor: pointer;
    font-size: 0.95rem;
    transition: all 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .calendar-day:hover:not(:disabled) {
    background: #f8f9fa;
    border-color: #667eea;
    transform: scale(1.05);
  }

  .calendar-day.other-month {
    color: #ccc;
    background: #f8f9fa;
  }

  .calendar-day.today {
    border-color: #667eea;
    font-weight: 600;
    color: #667eea;
  }

  .calendar-day.past,
  .calendar-day:disabled {
    cursor: not-allowed;
    opacity: 0.4;
  }

  .calendar-day.off-day {
    cursor: not-allowed;
    opacity: 0.25;
    background: #f8f9fa;
  }  .calendar-day.off-day {
    cursor: not-allowed;
    opacity: 0.25;
    background: #f8f9fa;
  }

  .calendar-day.selected {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border-color: #667eea;
    font-weight: 600;
  }

  @media (max-width: 768px) {
    .calendar-grid {
      gap: 0.25rem;
    }

    .weekdays {
      gap: 0.25rem;
    }

    .weekday {
      font-size: 0.75rem;
      padding: 0.25rem;
    }

    .calendar-day {
      font-size: 0.85rem;
    }
  }
</style>