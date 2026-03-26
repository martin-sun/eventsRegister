<script lang="ts">
	import { Mail, KeyRound, ArrowRight, ArrowLeft, Loader2 } from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { supabaseAuth } from '$lib/supabase-auth';
	import { goto } from '$app/navigation';

	let email = $state('');
	let otpCode = $state('');
	let step = $state<'email' | 'code'>('email');
	let sending = $state(false);
	let verifying = $state(false);
	let error = $state<string | null>(null);

	async function sendOtp() {
		if (!email.trim()) return;
		sending = true;
		error = null;

		const { error: err } = await supabaseAuth.auth.signInWithOtp({
			email: email.trim(),
			options: { shouldCreateUser: false }
		});

		sending = false;
		if (err) {
			error = m.admin_login_error_send();
		} else {
			step = 'code';
		}
	}

	async function verifyOtp() {
		if (!otpCode.trim()) return;
		verifying = true;
		error = null;

		const { data, error: err } = await supabaseAuth.auth.verifyOtp({
			email: email.trim(),
			token: otpCode.trim(),
			type: 'email'
		});

		if (err) {
			verifying = false;
			error = m.admin_login_error_verify();
			return;
		}

		// Check admin role
		const role = data.user?.app_metadata?.role;
		if (role !== 'admin') {
			await supabaseAuth.auth.signOut();
			verifying = false;
			error = m.admin_login_error_not_admin();
			return;
		}

		verifying = false;
		goto('/admin');
	}

	function resetToEmail() {
		step = 'email';
		otpCode = '';
		error = null;
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

			{#if step === 'email'}
				<!-- Step 1: Enter Email -->
				<form onsubmit={(e) => { e.preventDefault(); sendOtp(); }}>
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
							{m.admin_login_send_code()}
							<ArrowRight class="h-5 w-5" />
						{/if}
					</button>
				</form>

			{:else}
				<!-- Step 2: Enter OTP Code -->
				<div class="mb-4 rounded-xl bg-primary/5 px-4 py-3 font-chinese text-sm text-primary">
					{m.admin_login_code_sent({ email })}
				</div>

				<form onsubmit={(e) => { e.preventDefault(); verifyOtp(); }}>
					<label for="otp-code" class="mb-2 block font-chinese text-sm font-medium text-slate-700">
						{m.admin_login_code()}
					</label>
					<div class="relative mb-6">
						<KeyRound class="pointer-events-none absolute left-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
						<input
							id="otp-code"
							type="text"
							bind:value={otpCode}
							placeholder={m.admin_login_code_placeholder()}
							maxlength="6"
							required
							autocomplete="one-time-code"
							class="w-full rounded-xl border border-slate-200 py-3.5 pl-11 pr-4 text-center text-xl font-bold tracking-[0.3em] text-slate-900 placeholder:text-slate-400 placeholder:tracking-normal placeholder:text-base placeholder:font-normal transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
					<button
						type="submit"
						disabled={verifying || otpCode.length < 6}
						class="flex w-full cursor-pointer items-center justify-center gap-2 rounded-xl bg-primary px-6 py-3.5 font-chinese text-base font-bold text-white transition-all duration-200 hover:bg-primary-dark disabled:cursor-not-allowed disabled:opacity-50"
					>
						{#if verifying}
							<Loader2 class="h-5 w-5 animate-spin" />
							{m.admin_login_verifying()}
						{:else}
							{m.admin_login_verify()}
						{/if}
					</button>
				</form>

				<div class="mt-4 flex justify-between">
					<button
						type="button"
						onclick={resetToEmail}
						class="flex cursor-pointer items-center gap-1 font-chinese text-sm text-slate-500 transition-colors hover:text-primary"
					>
						<ArrowLeft class="h-4 w-4" />
						{m.admin_login_change_email()}
					</button>
					<button
						type="button"
						onclick={sendOtp}
						disabled={sending}
						class="cursor-pointer font-chinese text-sm text-primary transition-colors hover:text-primary-dark disabled:opacity-50"
					>
						{m.admin_login_resend()}
					</button>
				</div>
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
