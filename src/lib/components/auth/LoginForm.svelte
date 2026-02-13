<script>
  import { supabase } from '$lib/supabaseClient';
  import { user } from '$lib/stores';
  import { goto } from '$app/navigation';

  let email = '';
  let password = '';
  let error = '';
  let loading = false;

  async function handleLogin() {
    loading = true;
    error = '';

    const { data, error: loginError } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (loginError) {
      error = 'Błąd logowania: ' + loginError.message;
      loading = false;
    } else {
      user.set(data.user);
      goto('/dashboard');
    }
  }
</script>

<div class="login-form">
  <h2>Zaloguj się</h2>
  
  {#if error}
    <p class="error">{error}</p>
  {/if}

  <form on:submit|preventDefault={handleLogin}>
    <div class="form-group">
      <label for="email">Email</label>
      <input 
        id="email"
        type="email" 
        bind:value={email} 
        placeholder="twoj@email.pl"
        required
      />
    </div>

    <div class="form-group">
      <label for="password">Hasło</label>
      <input 
        id="password"
        type="password" 
        bind:value={password}
        placeholder="Wprowadź hasło"
        required
      />
    </div>

    <button type="submit" disabled={loading}>
      {loading ? 'Logowanie...' : 'Zaloguj'}
    </button>
  </form>
</div>

<style>
  .login-form {
    max-width: 400px;
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

  input {
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

  button:disabled {
    background-color: #ccc;
  }

  .error {
    color: red;
    margin-bottom: 1rem;
  }
</style>