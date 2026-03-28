<script lang="ts">
	import { Mail, ArrowRight, Loader2, MailCheck } from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { supabaseAuth } from '$lib/supabase-auth';

	let email = $state('');
	let sent = $state(false);
	let sending = $state(false);
	let error = $state<string | null>(null);

	async function sendMagicLink() {
		if (!email.trim()) return;
		sending = true;
		error = null;

		const { error: err } = await supabaseAuth.auth.signInWithOtp({
			email: email.trim(),
			options: {
				shouldCreateUser: false,
				emailRedirectTo: `${window.location.origin}/admin/login/callback`
			}
		});

		sending = false;
		if (err) {
			error = m.admin_login_error_send();
		} else {
			sent = true;
		}
	}
</script>

<svelte:head>
	<title>{m.admin_login_title()}</title>
</svelte:head>

<section class="flex min-h-screen items-center justify-center bg-slate-50 px-4">
	<div class="w-full max-w-md">
		<!-- Logo -->
		<div class="mb-8 text-center">
			<div class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary font-heading text-2xl text-white">
				BC
			</div>
			<h1 class="font-heading text-3xl tracking-wide text-primary-darker">
				{m.admin_login_title()}
			</h1>
			<p class="mt-2 font-chinese text-sm text-slate-500">
				{m.admin_login_subtitle()}
			</p>
		</div>

		<!-- Card -->
		<div class="rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
			{#if error}
				<div class="mb-6 rounded-xl bg-danger/5 px-4 py-3 font-chinese text-sm text-danger">
					{error}
				</div>
			{/if}

			{#if !sent}
				<!-- Step 1: Enter Email -->
				<form onsubmit={(e) => { e.preventDefault(); sendMagicLink(); }}>
					<label for="admin-email" class="mb-2 block font-chinese text-sm font-medium text-slate-700">
						{m.admin_login_email()}
					</label>
					<div class="relative mb-6">
						<Mail class="pointer-events-none absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
						<input
							id="admin-email"
							type="email"
							bind:value={email}
							placeholder={m.admin_login_email_placeholder()}
							required
							class="w-full rounded-xl border border-slate-200 py-3.5 pl-11 pr-4 text-base text-slate-900 placeholder:text-slate-400 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
					<button
						type="submit"
						disabled={sending || !email.trim()}
						class="flex w-full cursor-pointer items-center justify-center gap-2 rounded-xl bg-primary px-6 py-3.5 font-chinese text-base font-bold text-white transition-all duration-200 hover:bg-primary-dark disabled:cursor-not-allowed disabled:opacity-50"
					>
						{#if sending}
							<Loader2 class="h-5 w-5 animate-spin" />
							{m.admin_login_sending()}
						{:else}
							{m.admin_login_send_link()}
							<ArrowRight class="h-5 w-5" />
						{/if}
					</button>
				</form>
			{:else}
				<!-- Step 2: Check your email -->
				<div class="mb-6 flex flex-col items-center gap-3 py-4">
					<MailCheck class="h-12 w-12 text-primary" />
					<p class="font-chinese text-center text-sm text-slate-600">
						{m.admin_login_link_sent({ email })}
					</p>
				</div>

				<button
					type="button"
					onclick={() => { sent = false; error = null; }}
					class="flex w-full cursor-pointer items-center justify-center gap-2 rounded-xl border border-slate-200 px-6 py-3.5 font-chinese text-base font-medium text-slate-600 transition-all duration-200 hover:bg-slate-50"
				>
					{m.admin_login_change_email()}
				</button>

				<button
					type="button"
					onclick={sendMagicLink}
					disabled={sending}
					class="mt-3 flex w-full cursor-pointer items-center justify-center gap-1 font-chinese text-sm text-primary transition-colors hover:text-primary-dark disabled:opacity-50"
				>
					{#if sending}
						<Loader2 class="inline h-4 w-4 animate-spin" />
					{/if}
					{m.admin_login_resend()}
				</button>
			{/if}
		</div>

		<!-- Back link -->
		<div class="mt-6 text-center">
			<a href="/" class="font-chinese text-sm text-slate-500 transition-colors hover:text-primary">
				{m.admin_nav_back_site()}
			</a>
		</div>
	</div>
</section>
