<script>
  import RegisterForm from '$lib/components/auth/RegisterForm.svelte';
  import LoginForm from '$lib/components/auth/LoginForm.svelte';
  import { user } from '$lib/stores';
  import { goto } from '$app/navigation';

  $: if ($user) {
    goto('/dashboard');
  }
</script>

<h1>Planner SaaS</h1>

<LoginForm />
<hr />
<RegisterForm />
