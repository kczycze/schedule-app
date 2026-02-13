<script>
	import favicon from '$lib/assets/favicon.svg';
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabaseClient';
	import { user, session } from '$lib/stores';

	let { children } = $props();

	onMount(async () => {
		const {
			data: { session: currentSession }
		} = await supabase.auth.getSession();

		session.set(currentSession);
		user.set(currentSession?.user ?? null);

		supabase.auth.onAuthStateChange((_event, newSession) => {
			session.set(newSession);
			user.set(newSession?.user ?? null);
		});
	});
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{@render children()}
