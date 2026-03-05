<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabaseClient';
  import { goto } from '$app/navigation';
  import Dashboard from '$lib/components/owner/Dashboard.svelte';

  export let data;

  let loading = true;

  onMount(async () => {
    const { data } = await supabase.auth.getUser();

    if (!data.user) {
      goto('/');
      return;
    }

    loading = false;
  });
</script>

{#if loading}
  <p>Ładowanie...</p>
{:else}
 <Dashboard bookings={data.bookings} />
{/if}
