<script lang="ts">
	import { onMount } from 'svelte';
	import { supabaseAuth } from '$lib/supabase-auth';
	import { goto } from '$app/navigation';
	import { Loader2 } from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';

	let error = $state<string | null>(null);

	async function handleCallback(session: { user: any; access_token: string } | null) {
		if (!session) {
			error = m.admin_login_error_verify();
			return false;
		}

		const role = session.user?.app_metadata?.role;
		if (role !== 'admin') {
			await supabaseAuth.auth.signOut();
			error = m.admin_login_error_not_admin();
			return false;
		}

		const secure = window.location.protocol === 'https:' ? '; Secure' : '';
		document.cookie = `admin-session=${session.access_token}; path=/admin; SameSite=Lax; max-age=3600${secure}`;
		goto('/admin');
		return true;
	}

	onMount(async () => {
		// 1. Check if session already established (e.g. Supabase auto-processed hash)
		const {
			data: { session: existing }
		} = await supabaseAuth.auth.getSession();
		if (existing?.user && existing.access_token) {
			const ok = await handleCallback({
				user: existing.user,
				access_token: existing.access_token
			});
			if (ok) return;
		}

		// 2. Try PKCE code exchange (?code=xxx)
		const params = new URLSearchParams(window.location.search);
		const code = params.get('code');
		if (code) {
			const { data, error: err } = await supabaseAuth.auth.exchangeCodeForSession(code);
			if (!err && data.session) {
				const ok = await handleCallback({
					user: data.session.user,
					access_token: data.session.access_token
				});
				if (ok) return;
			}
		}

		error = m.admin_login_error_verify();
	});
</script>

<svelte:head>
	<title>{m.admin_login_title()}</title>
</svelte:head>

<section class="flex min-h-screen items-center justify-center bg-slate-50 px-4">
	<div class="w-full max-w-md text-center">
		{#if error}
			<div class="rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
				<div class="rounded-xl bg-danger/5 px-4 py-3 font-chinese text-sm text-danger">
					{error}
				</div>
				<a
					href="/admin/login"
					class="mt-4 inline-block font-chinese text-sm text-primary transition-colors hover:text-primary-dark"
				>
					{m.admin_login_change_email()}
				</a>
			</div>
		{:else}
			<Loader2 class="mx-auto h-8 w-8 animate-spin text-primary" />
			<p class="mt-4 font-chinese text-sm text-slate-500">{m.admin_login_verifying()}</p>
		{/if}
	</div>
</section>
