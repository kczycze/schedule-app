<script>
  import { supabase } from '$lib/supabaseClient';
  import { goto } from '$app/navigation';

  let email = '';
  let password = '';
  let confirmPassword = '';
  let companyName = '';
  let companySlug = '';
  let error = '';
  let loading = false;

  // Auto-generate slug from company name
  $: {
    companySlug = companyName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
  }

  async function handleRegister() {
    loading = true;
    error = '';

    companyName = companyName.trim();

if (companyName.length < 2) {
  error = 'Nazwa firmy musi mieć co najmniej 2 znaki.';
  loading = false;
  return;
}

if (!companySlug || companySlug.length < 2) {
  error = 'Adres URL jest nieprawidłowy.';
  loading = false;
  return;
}

if (!/^[a-z0-9-]+$/.test(companySlug)) {
  error = 'Adres URL zawiera niedozwolone znaki.';
  loading = false;
  return;
}

if (password.length < 6) {
  error = 'Hasło musi mieć min. 6 znaków.';
  loading = false;
  return;
}

if (password !== confirmPassword) {
  error = 'Hasła nie są identyczne.';
  loading = false;
  return;
}


// SPRAWDŹ CZY SLUG ISTNIEJE
if (!companySlug) {
  error = 'Podaj poprawną nazwę firmy.';
  loading = false;
  return;
}

const { data: existingCompany, error: checkError } = await supabase
  .from('companies')
  .select('id')
  .eq('slug', companySlug)
  .maybeSingle();

if (checkError) {
  error = 'Błąd sprawdzania dostępności nazwy.';
  loading = false;
  return;
}

if (existingCompany) {
  error = 'Firma o takiej nazwie już istnieje.';
  loading = false;
  return;
}

    // Step 1: Create auth user
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password
    });

    if (authError) {
      error = 'Błąd rejestracji: ' + authError.message;
      loading = false;
      return;
    }

    // Step 2: Create company record
const { error: companyError } = await supabase
  .from('companies')
  .insert({
    name: companyName,
    slug: companySlug,
  });

if (companyError) {
  // UNIQUE violation (slug już istnieje)
  if (companyError.code === '23505') {
    error = 'Firma o takiej nazwie już istnieje. Wybierz inną nazwę.';
  } else {
    error = 'Błąd tworzenia firmy: ' + companyError.message;
  }

  loading = false;
  return;
}

    // Success - redirect to dashboard
    goto('/dashboard');
    loading = false;
  }

</script>

<div class="register-form">
  <h2>Zarejestruj się</h2>

  {#if error}
    <p class="error">{error}</p>
  {/if}

  <form on:submit|preventDefault={handleRegister}>
    <div class="form-group">
      <label for="companyName">Nazwa firmy</label>
      <input 
        id="companyName"
        type="text" 
        bind:value={companyName}
        placeholder="Salon Piękności"
        required
      />
    </div>

    <div class="form-group">
      <label for="companySlug">Adres URL (automatyczny)</label>
      <input 
        id="companySlug"
        type="text" 
        bind:value={companySlug}
        placeholder="salon-pieknosci"
        required
      />
      <small>Twój link: /{companySlug}</small>
    </div>

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
        placeholder="Min. 6 znaków"
        required
      />
    </div>

    <div class="form-group">
  <label for="confirmPassword">Powtórz hasło</label>
  <input 
    id="confirmPassword"
    type="password"
    bind:value={confirmPassword}
    placeholder="Powtórz hasło"
    required
  />
</div>

    <button type="submit" disabled={loading}>
      {loading ? 'Rejestracja...' : 'Zarejestruj'}
    </button>
  </form>
</div>

<style>
  /* Same as LoginForm.svelte */
  .register-form {
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

  small {
    color: #666;
    font-size: 0.85rem;
  }

  button {
    width: 100%;
    padding: 0.75rem;
    background-color: #2196F3;
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