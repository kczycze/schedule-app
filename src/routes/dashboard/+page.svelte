<script>
  import { onMount } from 'svelte';
  import { supabase } from '$lib/supabaseClient';
  import { goto } from '$app/navigation';

  let user = null;
  let company = null;
  let error = '';

  onMount(async () => {
    const { data } = await supabase.auth.getUser();
    user = data.user;

    if (!user) {
      goto('/login');
      return;
    }

    const { data: companyData, error: companyError } = await supabase
      .from('companies')
      .select('*')
      .limit(1)
      .maybeSingle();

    if (companyError) {
      error = companyError.message;
    } else {
      company = companyData;
    }
  });
</script>

<h1>Dashboard</h1>

{#if error}
  <p style="color:red;">{error}</p>
{/if}

{#if company}
  <p><strong>Firma:</strong> {company.name}</p>
  <p><strong>Slug:</strong> {company.slug}</p>
{/if}

{#if !company && !error}
  <p>Ładowanie...</p>
{/if}
