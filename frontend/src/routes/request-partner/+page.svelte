<script lang="ts">
	import {
		User,
		Check,
		ChevronRight,
		Mail,
		Phone,
		MessageCircle,
		AlertCircle,
		CircleCheck,
		Home,
		ClipboardList,
		Users
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import DateInput from '$lib/components/DateInput.svelte';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import { enhance } from '$app/forms';

	let { data, form } = $props();

	let submitting = $state(false);
	let serverError = $state<string | null>(null);
	let submitted = $state(false);

	let player = $state({
		firstName: '',
		lastName: '',
		gender: '' as '' | 'male' | 'female',
		dob: '',
		email: '',
		phone: '',
		wechat: ''
	});

	let preferredCategory = $state('');
	let notes = $state('');

	let touched = $state({
		firstName: false,
		lastName: false,
		gender: false,
		dob: false,
		email: false
	});

	// --- Age Calculation ---
	let TOURNAMENT_DATE = $derived(new Date(data.config.tournament_date));

	function calculateAge(dobStr: string): number | null {
		if (!dobStr) return null;
		const birth = new Date(dobStr);
		if (isNaN(birth.getTime())) return null;
		let age = TOURNAMENT_DATE.getFullYear() - birth.getFullYear();
		const monthDiff = TOURNAMENT_DATE.getMonth() - birth.getMonth();
		if (monthDiff < 0 || (monthDiff === 0 && TOURNAMENT_DATE.getDate() < birth.getDate())) {
			age--;
		}
		return age;
	}

	let age = $derived(calculateAge(player.dob));

	// --- Validation ---
	function isValidEmail(email: string): boolean {
		return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
	}

	let errors = $derived.by(() => {
		const errors: Record<string, string> = {};
		if (touched.firstName && !player.firstName.trim()) errors.firstName = m.reg_err_first_name();
		if (touched.lastName && !player.lastName.trim()) errors.lastName = m.reg_err_last_name();
		if (touched.gender && !player.gender) errors.gender = m.reg_err_gender();
		if (touched.dob) {
			if (!player.dob) {
				errors.dob = m.reg_err_dob();
			}
		}
		if (touched.email) {
			if (!player.email.trim()) {
				errors.email = m.reg_err_email_required();
			} else if (!isValidEmail(player.email)) {
				errors.email = m.reg_err_email_invalid();
			}
		}
		return errors;
	});

	let formValid = $derived(
		player.firstName.trim() !== '' &&
		player.lastName.trim() !== '' &&
		player.gender !== '' &&
		player.dob !== '' &&
		player.email.trim() !== '' &&
		isValidEmail(player.email)
	);

	function touchAllFields() {
		touched = { firstName: true, lastName: true, gender: true, dob: true, email: true };
	}

	function handleEnhance() {
		submitting = true;
		serverError = null;
		return async ({ result }: { result: import('@sveltejs/kit').ActionResult }) => {
			submitting = false;
			if (result.type === 'success' && result.data?.success) {
				submitted = true;
				window.scrollTo({ top: 0, behavior: 'smooth' });
			} else if (result.type === 'failure') {
				serverError = result.data?.error ?? 'unknown_error';
			}
		};
	}

	const errorMessages: Record<string, () => string> = {
		missing_fields: () => m.rp_err_missing_fields(),
		email_invalid: () => m.rp_err_email_invalid(),
		send_failed: () => m.rp_err_send_failed()
	};

	// Category options from config
	let categoryOptions = $derived.by(() => {
		const cats = data.categories ?? [];
		return cats.map((c: { name_en: string; name_zh: string; slug: string }) => ({
			value: c.slug,
			label: getLocale() === 'zh' ? c.name_zh : c.name_en
		}));
	});
</script>

<svelte:head>
	<title>{m.rp_page_title()}</title>
</svelte:head>

<!-- ============================================ -->
<!-- PAGE CONTAINER                               -->
<!-- ============================================ -->
<section class="min-h-screen bg-surface py-8 sm:py-12">
	<div class="mx-auto max-w-2xl px-4">

		{#if !submitted}
			<!-- Page Title -->
			<div class="mb-8 text-center">
				<h1 class="mb-2 font-heading text-4xl tracking-wide text-primary-darker sm:text-5xl">
					{m.rp_title()}
				</h1>
				<p class="font-chinese text-slate-500">{m.rp_subtitle()}</p>
			</div>

			<form method="POST" action="?/submit" use:enhance={handleEnhance}>
				<input type="hidden" name="locale" value={getLocale()} />
				<input type="hidden" name="gender" value={player.gender} />
				<input type="hidden" name="dob" value={player.dob} />

				<!-- Server Error -->
				{#if serverError}
					<div class="mb-6 rounded-2xl border border-danger/20 bg-danger/5 p-4 text-center">
						<div class="flex items-center justify-center gap-2 font-chinese text-sm font-medium text-danger">
							<AlertCircle class="h-5 w-5" />
							{errorMessages[serverError]?.() ?? m.rp_err_send_failed()}
						</div>
					</div>
				{/if}

				<!-- Player Info Card -->
				<div class="mb-6 overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
					<div class="flex items-center gap-3 border-b border-slate-100 bg-primary/5 px-6 py-4">
						<div class="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
							<User class="h-4 w-4" />
						</div>
						<div>
							<h2 class="font-chinese text-lg font-bold text-slate-900">{m.rp_player_title()}</h2>
						</div>
					</div>

					<div class="space-y-5 p-6">
						<!-- Name Row -->
						<div class="grid grid-cols-2 gap-4">
							<div>
								<label for="first" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
									{m.reg_first_name()} <span class="text-danger">{m.reg_required()}</span>
								</label>
								<input
									id="first"
									name="firstName"
									type="text"
									bind:value={player.firstName}
									onblur={() => (touched.firstName = true)}
									placeholder="e.g. Wei"
									class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
									{errors.firstName ? 'border-danger ring-2 ring-danger/20' : ''}"
								/>
								{#if errors.firstName}
									<p class="mt-1 font-chinese text-xs text-danger">{errors.firstName}</p>
								{/if}
							</div>
							<div>
								<label for="last" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
									{m.reg_last_name()} <span class="text-danger">{m.reg_required()}</span>
								</label>
								<input
									id="last"
									name="lastName"
									type="text"
									bind:value={player.lastName}
									onblur={() => (touched.lastName = true)}
									placeholder="e.g. Zhang"
									class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
									{errors.lastName ? 'border-danger ring-2 ring-danger/20' : ''}"
								/>
								{#if errors.lastName}
									<p class="mt-1 font-chinese text-xs text-danger">{errors.lastName}</p>
								{/if}
							</div>
						</div>

						<!-- Gender -->
						<fieldset>
							<legend class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_gender()} <span class="text-danger">{m.reg_required()}</span>
							</legend>
							<div class="flex gap-3">
								<button
									type="button"
									onclick={() => { player.gender = 'male'; touched.gender = true; }}
									class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
									{player.gender === 'male' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
								>
									{m.reg_gender_male()}
								</button>
								<button
									type="button"
									onclick={() => { player.gender = 'female'; touched.gender = true; }}
									class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
									{player.gender === 'female' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
								>
									{m.reg_gender_female()}
								</button>
							</div>
							{#if errors.gender}
								<p class="mt-1 font-chinese text-xs text-danger">{errors.gender}</p>
							{/if}
						</fieldset>

						<!-- DOB -->
						<div>
							<label class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_dob()} <span class="text-danger">{m.reg_required()}</span>
							</label>
							<div class="flex items-center gap-3">
								<DateInput
									bind:value={player.dob}
									hasError={!!errors.dob}
									onBlur={() => (touched.dob = true)}
								/>
								{#if age !== null}
									<span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1.5 text-xs font-bold text-primary">
										{age}{m.reg_age_suffix()}
									</span>
								{/if}
							</div>
							{#if errors.dob}
								<p class="mt-1 font-chinese text-xs text-danger">{errors.dob}</p>
							{/if}
						</div>

						<!-- Email -->
						<div>
							<label for="email" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_email()} <span class="text-danger">{m.reg_required()}</span>
							</label>
							<div class="relative">
								<Mail class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
								<input
									id="email"
									name="email"
									type="email"
									bind:value={player.email}
									onblur={() => (touched.email = true)}
									placeholder="email@example.com"
									class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
									{errors.email ? 'border-danger ring-2 ring-danger/20' : ''}"
								/>
							</div>
							{#if errors.email}
								<p class="mt-1 font-chinese text-xs text-danger">{errors.email}</p>
							{/if}
						</div>

						<!-- Phone -->
						<div>
							<label for="phone" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_phone()} <span class="text-slate-400 font-normal">({m.reg_optional()})</span>
							</label>
							<div class="relative">
								<Phone class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
								<input
									id="phone"
									name="phone"
									type="tel"
									bind:value={player.phone}
									placeholder="+1 (306) 555-0000"
									class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
								/>
							</div>
						</div>

						<!-- WeChat -->
						<div>
							<label for="wechat" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_wechat()} <span class="text-slate-400 font-normal">({m.reg_optional()})</span>
							</label>
							<div class="relative">
								<MessageCircle class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
								<input
									id="wechat"
									name="wechat"
									type="text"
									bind:value={player.wechat}
									placeholder="WeChat ID"
									class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
								/>
							</div>
						</div>
					</div>
				</div>

				<!-- Preferred Category Card -->
				<div class="mb-6 overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
					<div class="flex items-center gap-3 border-b border-slate-100 bg-cta/5 px-6 py-4">
						<div class="flex h-8 w-8 items-center justify-center rounded-lg bg-cta/10 text-cta">
							<ClipboardList class="h-4 w-4" />
						</div>
						<h2 class="font-chinese text-lg font-bold text-slate-900">{m.rp_preferred_category()}</h2>
					</div>
					<div class="p-6 space-y-4">
						<select
							name="preferredCategory"
							bind:value={preferredCategory}
							class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						>
							<option value="">{m.rp_preferred_category_any()}</option>
							{#each categoryOptions as opt}
								<option value={opt.label}>{opt.label}</option>
							{/each}
						</select>

						<!-- Notes -->
						<div>
							<label for="notes" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.rp_notes()} <span class="text-slate-400 font-normal">({m.reg_optional()})</span>
							</label>
							<textarea
								id="notes"
								name="notes"
								bind:value={notes}
								rows="3"
								placeholder={m.rp_notes_placeholder()}
								class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none resize-none"
							></textarea>
						</div>
					</div>
				</div>

				<!-- Submit Button -->
				<div class="fixed bottom-0 left-0 right-0 border-t border-slate-200 bg-white/95 p-4 backdrop-blur-sm sm:static sm:mt-6 sm:border-0 sm:bg-transparent sm:p-0 sm:backdrop-blur-none">
					<div class="mx-auto flex max-w-2xl justify-end">
						<button
							type="submit"
							disabled={!formValid || submitting}
							class="inline-flex w-full cursor-pointer items-center justify-center gap-2 rounded-xl px-8 py-4 font-chinese text-base font-bold text-white shadow-lg transition-all duration-200 sm:w-auto
							{formValid && !submitting ? 'bg-cta hover:-translate-y-0.5 hover:bg-cta-hover hover:shadow-xl' : 'bg-slate-300 cursor-not-allowed shadow-none'}"
						>
							{#if submitting}
								{m.rp_submitting()}
							{:else}
								{m.rp_submit()}
								<ChevronRight class="h-5 w-5" />
							{/if}
						</button>
					</div>
				</div>
				<!-- Spacer for fixed bottom bar on mobile -->
				<div class="h-20 sm:hidden"></div>
			</form>

		{:else}
			<!-- ============================================ -->
			<!-- SUCCESS STATE                                -->
			<!-- ============================================ -->
			<div class="py-12 text-center">
				<div class="mx-auto mb-6 flex h-24 w-24 items-center justify-center rounded-full bg-primary/10">
					<CircleCheck class="h-14 w-14 text-primary" />
				</div>

				<h2 class="mb-2 font-heading text-4xl tracking-wide text-primary-darker sm:text-5xl">
					{m.rp_success_title()}
				</h2>
				<p class="mb-8 font-chinese text-slate-500">
					{m.rp_success_subtitle()}
				</p>

				<!-- Action Buttons -->
				<div class="flex flex-col gap-3 sm:flex-row sm:justify-center">
					<a
						href="/register"
						class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-xl bg-cta px-8 py-4 font-chinese text-base font-bold text-white shadow-lg transition-all duration-200 hover:-translate-y-0.5 hover:bg-cta-hover hover:shadow-xl"
					>
						<Users class="h-5 w-5" />
						{m.rp_register_now()}
					</a>
					<a
						href="/"
						class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-xl border-2 border-slate-200 px-8 py-4 font-chinese text-base font-medium text-slate-600 transition-all duration-200 hover:border-slate-300 hover:bg-slate-50"
					>
						<Home class="h-5 w-5" />
						{m.rp_back_home()}
					</a>
				</div>
			</div>
		{/if}
	</div>
</section>
