<script lang="ts">
	import {
		User,
		Users,
		Check,
		ChevronLeft,
		ChevronRight,
		Calendar,
		Mail,
		Phone,
		MessageCircle,
		Trophy,
		AlertCircle,
		CircleCheck,
		CircleX,
		Copy,
		Home,
		Pencil,
		DollarSign,
		Heart,
		Clock
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import { enhance } from '$app/forms';

	let { data, form } = $props();

	// --- Constants (from tournament config) ---
	let TOURNAMENT_DATE = $derived(new Date(data.config.tournament_date));
	let MIN_INDIVIDUAL_AGE = $derived(data.config.min_age);

	// --- State ---
	let currentStep = $state(1);
	let submitting = $state(false);
	let serverError = $state<string | null>(null);
	let registrationResult = $state<{ teamId: string; status: string; genderType: string; combinedAge: number } | null>(null);
	let copiedField = $state<string | null>(null);

	let player1 = $state({
		firstName: '',
		lastName: '',
		gender: '' as '' | 'male' | 'female',
		dob: '',
		email: '',
		phone: '',
		wechat: ''
	});

	let player2 = $state({
		firstName: '',
		lastName: '',
		gender: '' as '' | 'male' | 'female',
		dob: '',
		email: '',
		phone: '',
		wechat: ''
	});

	let touched1 = $state({
		firstName: false,
		lastName: false,
		gender: false,
		dob: false,
		email: false
	});

	let touched2 = $state({
		firstName: false,
		lastName: false,
		gender: false,
		dob: false,
		email: false
	});

	// --- Age Calculation ---
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

	// --- Derived State ---
	let p1Age = $derived(calculateAge(player1.dob));
	let p2Age = $derived(calculateAge(player2.dob));
	let combinedAge = $derived(p1Age !== null && p2Age !== null ? p1Age + p2Age : null);

	// All eligible categories sorted by min_age_sum descending (highest first)
	let eligibleCategories = $derived.by(() => {
		if (combinedAge === null) return [];
		return data.categories
			.filter((c) => combinedAge >= c.min_age_sum && c.is_open)
			.sort((a, b) => b.min_age_sum - a.min_age_sum);
	});

	// User-selected category ID (null = use default highest)
	let selectedCategoryId = $state<string | null>(null);

	// Resolved selected category: user pick if valid, otherwise default to highest eligible
	let selectedCategory = $derived.by(() => {
		if (eligibleCategories.length === 0) return null;
		if (selectedCategoryId) {
			const found = eligibleCategories.find((c) => c.id === selectedCategoryId);
			if (found) return found;
		}
		return eligibleCategories[0];
	});

	// Minimum combined age across all open categories
	let minRequiredAge = $derived.by(() => {
		const openCats = data.categories.filter((c) => c.is_open);
		if (openCats.length === 0) return 0;
		return Math.min(...openCats.map((c) => c.min_age_sum));
	});

	let autoCategory = $derived.by(() => {
		if (combinedAge === null) return null;
		if (selectedCategory) return selectedCategory.slug;
		return 'ineligible';
	});

	let categoryName = $derived.by(() => {
		if (selectedCategory) return getLocale() === 'zh' ? selectedCategory.name_zh : selectedCategory.name_en;
		if (autoCategory === 'ineligible') return m.reg_ineligible({ minAge: minRequiredAge });
		return '';
	});

	let categoryNameEn = $derived.by(() => {
		if (selectedCategory) return selectedCategory.name_en;
		if (autoCategory === 'ineligible') return 'Ineligible';
		return '';
	});

	let genderType = $derived.by(() => {
		if (!player1.gender || !player2.gender) return null;
		if (player1.gender === 'male' && player2.gender === 'male') return 'mens';
		if (player1.gender === 'female' && player2.gender === 'female') return 'womens';
		return 'mixed';
	});

	let genderTypeLabel = $derived.by(() => {
		if (genderType === 'mens') return m.reg_mens();
		if (genderType === 'womens') return m.reg_womens();
		if (genderType === 'mixed') return m.reg_mixed();
		return '';
	});

	// --- Validation ---
	function isValidEmail(email: string): boolean {
		return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
	}

	let p1Errors = $derived.by(() => {
		const errors: Record<string, string> = {};
		if (touched1.firstName && !player1.firstName.trim()) errors.firstName = m.reg_err_first_name();
		if (touched1.lastName && !player1.lastName.trim()) errors.lastName = m.reg_err_last_name();
		if (touched1.gender && !player1.gender) errors.gender = m.reg_err_gender();
		if (touched1.dob) {
			if (!player1.dob) {
				errors.dob = m.reg_err_dob();
			} else if (p1Age !== null && p1Age < MIN_INDIVIDUAL_AGE) {
				errors.dob = m.reg_err_age({ min: MIN_INDIVIDUAL_AGE, age: p1Age });
			}
		}
		if (touched1.email) {
			if (!player1.email.trim()) {
				errors.email = m.reg_err_email_required();
			} else if (!isValidEmail(player1.email)) {
				errors.email = m.reg_err_email_invalid();
			}
		}
		return errors;
	});

	let p2Errors = $derived.by(() => {
		const errors: Record<string, string> = {};
		if (touched2.firstName && !player2.firstName.trim()) errors.firstName = m.reg_err_first_name();
		if (touched2.lastName && !player2.lastName.trim()) errors.lastName = m.reg_err_last_name();
		if (touched2.gender && !player2.gender) errors.gender = m.reg_err_gender();
		if (touched2.dob) {
			if (!player2.dob) {
				errors.dob = m.reg_err_dob();
			} else if (p2Age !== null && p2Age < MIN_INDIVIDUAL_AGE) {
				errors.dob = m.reg_err_age({ min: MIN_INDIVIDUAL_AGE, age: p2Age });
			}
		}
		if (touched2.email) {
			if (!player2.email.trim()) {
				errors.email = m.reg_err_email_required();
			} else if (!isValidEmail(player2.email)) {
				errors.email = m.reg_err_email_invalid();
			} else if (sameEmail) {
				errors.email = m.reg_err_same_player();
			}
		}
		return errors;
	});

	function isPlayerValid(
		p: typeof player1,
		age: number | null
	): boolean {
		return (
			p.firstName.trim() !== '' &&
			p.lastName.trim() !== '' &&
			p.gender !== '' &&
			p.dob !== '' &&
			age !== null &&
			age >= MIN_INDIVIDUAL_AGE &&
			p.email.trim() !== '' &&
			isValidEmail(p.email)
		);
	}

	let step1Valid = $derived(
		isPlayerValid(player1, p1Age) &&
			isPlayerValid(player2, p2Age) &&
			selectedCategory !== null
	);

	let sameEmail = $derived(
		player1.email.trim() !== '' &&
		player2.email.trim() !== '' &&
		player1.email.trim().toLowerCase() === player2.email.trim().toLowerCase()
	);

	let validationChecks = $derived.by(() => [
		{
			label: m.reg_check_age(),
			passed: p1Age !== null && p1Age >= 35 && p2Age !== null && p2Age >= 35
		},
		{
			label: m.reg_check_combined(),
			passed: selectedCategory !== null
		},
		{
			label: m.reg_check_info(),
			passed: isPlayerValid(player1, p1Age) && isPlayerValid(player2, p2Age) && !sameEmail
		},
		{
			label: m.reg_check_type(),
			passed: genderType !== null
		}
	]);

	let allChecksPass = $derived(validationChecks.every((c) => c.passed));

	// --- Actions ---
	function touchAllFields() {
		touched1 = { firstName: true, lastName: true, gender: true, dob: true, email: true };
		touched2 = { firstName: true, lastName: true, gender: true, dob: true, email: true };
	}

	function goToStep(step: number) {
		if (step === 2 && !step1Valid) {
			touchAllFields();
			return;
		}
		currentStep = step;
		window.scrollTo({ top: 0, behavior: 'smooth' });
	}

	function handleEnhance() {
		submitting = true;
		serverError = null;
		return async ({ result }: { result: import('@sveltejs/kit').ActionResult }) => {
			submitting = false;
			if (result.type === 'success' && result.data?.success) {
				registrationResult = result.data as typeof registrationResult;
				currentStep = 3;
				window.scrollTo({ top: 0, behavior: 'smooth' });
			} else if (result.type === 'failure') {
				serverError = result.data?.error ?? 'unknown_error';
			}
		};
	}

	// Map server error keys to i18n messages
	const errorMessages: Record<string, () => string> = {
		combined_age_insufficient: () => m.reg_err_combined_age(),
		individual_age_insufficient: () => m.reg_err_individual_age(),
		player_already_registered: () => m.reg_err_already_registered(),
		registration_closed: () => m.reg_err_registration_closed(),
		rate_limited: () => m.reg_err_rate_limited(),
		email_conflict: () => m.reg_err_email_conflict(),
		same_player: () => m.reg_err_same_player(),
		missing_player1_fields: () => m.reg_err_missing_fields(),
		missing_player2_fields: () => m.reg_err_missing_fields(),
		missing_category: () => m.reg_err_missing_fields(),
		unknown_error: () => m.reg_err_unknown()
	};

	// --- Step labels ---
	let steps = $derived([
		{ num: 1, label: m.reg_step_info() },
		{ num: 2, label: m.reg_step_confirm() },
		{ num: 3, label: m.reg_step_done() }
	]);
</script>

<svelte:head>
	<title>{m.reg_page_title()}</title>
</svelte:head>

<!-- ============================================ -->
<!-- PAGE CONTAINER                               -->
<!-- ============================================ -->
<section class="min-h-screen bg-surface py-8 sm:py-12">
	<div class="mx-auto max-w-2xl px-4">
		<!-- Page Title -->
		<div class="mb-8 text-center">
			<h1 class="mb-2 font-heading text-4xl tracking-wide text-primary-darker sm:text-5xl">
				{m.reg_title()}
			</h1>
			<p class="font-chinese text-slate-500">{m.reg_subtitle()}</p>
		</div>

		<!-- ============================================ -->
		<!-- PROGRESS INDICATOR                           -->
		<!-- ============================================ -->
		<div class="mb-10 flex items-center justify-center gap-0">
			{#each steps as step, i}
				{@const isCompleted = currentStep > step.num}
				{@const isCurrent = currentStep === step.num}
				{@const isFuture = currentStep < step.num}

				<!-- Step circle + label -->
				<div class="flex flex-col items-center">
					<div
						class="flex h-10 w-10 items-center justify-center rounded-full text-sm font-bold transition-all duration-300
						{isCompleted ? 'bg-primary text-white' : ''}
						{isCurrent ? 'bg-cta text-white shadow-lg shadow-cta/30' : ''}
						{isFuture ? 'bg-slate-200 text-slate-400' : ''}"
					>
						{#if isCompleted}
							<Check class="h-5 w-5" />
						{:else}
							{step.num}
						{/if}
					</div>
					<span
						class="mt-2 font-chinese text-xs font-medium
						{isCompleted ? 'text-primary' : ''}
						{isCurrent ? 'text-cta' : ''}
						{isFuture ? 'text-slate-400' : ''}"
					>
						{step.label}
					</span>
				</div>

				<!-- Connector line -->
				{#if i < steps.length - 1}
					<div
						class="mx-3 mb-6 h-0.5 w-16 rounded-full transition-all duration-300 sm:w-24
						{currentStep > step.num + 1 ? 'bg-primary' : ''}
						{currentStep === step.num + 1 ? 'bg-gradient-to-r from-primary to-slate-200' : ''}
						{currentStep <= step.num ? 'bg-slate-200' : ''}"
					></div>
				{/if}
			{/each}
		</div>

		<!-- ============================================ -->
		<!-- STEP 1: PLAYER INFO                         -->
		<!-- ============================================ -->
		{#if currentStep === 1}
			<!-- Player 1 Card -->
			<div class="mb-6 overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
				<div class="flex items-center gap-3 border-b border-slate-100 bg-primary/5 px-6 py-4">
					<div class="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10 text-primary">
						<User class="h-4 w-4" />
					</div>
					<div>
						<h2 class="font-chinese text-lg font-bold text-slate-900">{m.reg_player1_title()}</h2>
					</div>
				</div>

				<div class="space-y-5 p-6">
					<!-- Name Row -->
					<div class="grid grid-cols-2 gap-4">
						<div>
							<label for="p1-first" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_first_name()} <span class="text-danger">{m.reg_required()}</span>
							</label>
							<input
								id="p1-first"
								type="text"
								bind:value={player1.firstName}
								onblur={() => (touched1.firstName = true)}
								placeholder="e.g. Wei"
								class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p1Errors.firstName ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
							{#if p1Errors.firstName}
								<p class="mt-1 font-chinese text-xs text-danger">{p1Errors.firstName}</p>
							{/if}
						</div>
						<div>
							<label for="p1-last" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_last_name()} <span class="text-danger">{m.reg_required()}</span>
							</label>
							<input
								id="p1-last"
								type="text"
								bind:value={player1.lastName}
								onblur={() => (touched1.lastName = true)}
								placeholder="e.g. Zhang"
								class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p1Errors.lastName ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
							{#if p1Errors.lastName}
								<p class="mt-1 font-chinese text-xs text-danger">{p1Errors.lastName}</p>
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
								onclick={() => { player1.gender = 'male'; touched1.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player1.gender === 'male' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								{m.reg_gender_male()}
							</button>
							<button
								type="button"
								onclick={() => { player1.gender = 'female'; touched1.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player1.gender === 'female' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								{m.reg_gender_female()}
							</button>
						</div>
						{#if p1Errors.gender}
							<p class="mt-1 font-chinese text-xs text-danger">{p1Errors.gender}</p>
						{/if}
					</fieldset>

					<!-- DOB -->
					<div>
						<label for="p1-dob" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_dob()} <span class="text-danger">{m.reg_required()}</span>
						</label>
						<div class="flex items-center gap-3">
							<input
								id="p1-dob"
								type="date"
								bind:value={player1.dob}
								onblur={() => (touched1.dob = true)}
								class="flex-1 rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p1Errors.dob ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
							{#if p1Age !== null}
								<span
									class="inline-flex items-center gap-1 rounded-full px-3 py-1.5 text-xs font-bold
									{p1Age >= MIN_INDIVIDUAL_AGE ? 'bg-primary/10 text-primary' : 'bg-danger/10 text-danger'}"
								>
									{p1Age}{m.reg_age_suffix()}
								</span>
							{/if}
						</div>
						{#if p1Errors.dob}
							<p class="mt-1 font-chinese text-xs text-danger">{p1Errors.dob}</p>
						{/if}
					</div>

					<!-- Email -->
					<div>
						<label for="p1-email" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_email()} <span class="text-danger">{m.reg_required()}</span>
						</label>
						<div class="relative">
							<Mail class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
							<input
								id="p1-email"
								type="email"
								bind:value={player1.email}
								onblur={() => (touched1.email = true)}
								placeholder="email@example.com"
								class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p1Errors.email ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
						</div>
						{#if p1Errors.email}
							<p class="mt-1 font-chinese text-xs text-danger">{p1Errors.email}</p>
						{/if}
					</div>

					<!-- Phone -->
					<div>
						<label for="p1-phone" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_phone()} <span class="text-slate-400 font-normal">({m.reg_optional()})</span>
						</label>
						<div class="relative">
							<Phone class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
							<input
								id="p1-phone"
								type="tel"
								bind:value={player1.phone}
								placeholder="+1 (306) 555-0000"
								class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
							/>
						</div>
					</div>

					<!-- WeChat -->
					<div>
						<label for="p1-wechat" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_wechat()} <span class="text-slate-400 font-normal">({m.reg_optional()})</span>
						</label>
						<div class="relative">
							<MessageCircle class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
							<input
								id="p1-wechat"
								type="text"
								bind:value={player1.wechat}
								placeholder="WeChat ID"
								class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
							/>
						</div>
					</div>
				</div>
			</div>

			<!-- Player 2 Card -->
			<div class="mb-6 overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
				<div class="flex items-center gap-3 border-b border-slate-100 bg-cta/5 px-6 py-4">
					<div class="flex h-8 w-8 items-center justify-center rounded-lg bg-cta/10 text-cta">
						<Users class="h-4 w-4" />
					</div>
					<div>
						<h2 class="font-chinese text-lg font-bold text-slate-900">{m.reg_player2_title()}</h2>
					</div>
				</div>

				<div class="space-y-5 p-6">
					<!-- Name Row -->
					<div class="grid grid-cols-2 gap-4">
						<div>
							<label for="p2-first" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_first_name()} <span class="text-danger">{m.reg_required()}</span>
							</label>
							<input
								id="p2-first"
								type="text"
								bind:value={player2.firstName}
								onblur={() => (touched2.firstName = true)}
								placeholder="e.g. Li"
								class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p2Errors.firstName ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
							{#if p2Errors.firstName}
								<p class="mt-1 font-chinese text-xs text-danger">{p2Errors.firstName}</p>
							{/if}
						</div>
						<div>
							<label for="p2-last" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								{m.reg_last_name()} <span class="text-danger">{m.reg_required()}</span>
							</label>
							<input
								id="p2-last"
								type="text"
								bind:value={player2.lastName}
								onblur={() => (touched2.lastName = true)}
								placeholder="e.g. Wang"
								class="w-full rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p2Errors.lastName ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
							{#if p2Errors.lastName}
								<p class="mt-1 font-chinese text-xs text-danger">{p2Errors.lastName}</p>
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
								onclick={() => { player2.gender = 'male'; touched2.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player2.gender === 'male' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								{m.reg_gender_male()}
							</button>
							<button
								type="button"
								onclick={() => { player2.gender = 'female'; touched2.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player2.gender === 'female' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								{m.reg_gender_female()}
							</button>
						</div>
						{#if p2Errors.gender}
							<p class="mt-1 font-chinese text-xs text-danger">{p2Errors.gender}</p>
						{/if}
					</fieldset>

					<!-- DOB -->
					<div>
						<label for="p2-dob" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_dob()} <span class="text-danger">{m.reg_required()}</span>
						</label>
						<div class="flex items-center gap-3">
							<input
								id="p2-dob"
								type="date"
								bind:value={player2.dob}
								onblur={() => (touched2.dob = true)}
								class="flex-1 rounded-xl border border-slate-200 px-4 py-3 text-base text-slate-900 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p2Errors.dob ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
							{#if p2Age !== null}
								<span
									class="inline-flex items-center gap-1 rounded-full px-3 py-1.5 text-xs font-bold
									{p2Age >= MIN_INDIVIDUAL_AGE ? 'bg-primary/10 text-primary' : 'bg-danger/10 text-danger'}"
								>
									{p2Age}{m.reg_age_suffix()}
								</span>
							{/if}
						</div>
						{#if p2Errors.dob}
							<p class="mt-1 font-chinese text-xs text-danger">{p2Errors.dob}</p>
						{/if}
					</div>

					<!-- Email -->
					<div>
						<label for="p2-email" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_email()} <span class="text-danger">{m.reg_required()}</span>
						</label>
						<div class="relative">
							<Mail class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
							<input
								id="p2-email"
								type="email"
								bind:value={player2.email}
								onblur={() => (touched2.email = true)}
								placeholder="email@example.com"
								class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none
								{p2Errors.email ? 'border-danger ring-2 ring-danger/20' : ''}"
							/>
						</div>
						{#if p2Errors.email}
							<p class="mt-1 font-chinese text-xs text-danger">{p2Errors.email}</p>
						{/if}
					</div>

					<!-- Phone -->
					<div>
						<label for="p2-phone" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_phone()} <span class="text-slate-400 font-normal">({m.reg_optional()})</span>
						</label>
						<div class="relative">
							<Phone class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
							<input
								id="p2-phone"
								type="tel"
								bind:value={player2.phone}
								placeholder="+1 (306) 555-0000"
								class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
							/>
						</div>
					</div>

					<!-- WeChat -->
					<div>
						<label for="p2-wechat" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							{m.reg_wechat()} <span class="text-slate-400 font-normal">({m.reg_optional()})</span>
						</label>
						<div class="relative">
							<MessageCircle class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
							<input
								id="p2-wechat"
								type="text"
								bind:value={player2.wechat}
								placeholder="WeChat ID"
								class="w-full rounded-xl border border-slate-200 py-3 pl-10 pr-4 text-base text-slate-900 placeholder:text-slate-300 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
							/>
						</div>
					</div>
				</div>
			</div>

			<!-- Auto-calculated Section -->
			{#if combinedAge !== null}
				<div class="mb-6 grid gap-4 sm:grid-cols-2">
					<!-- Combined Age Card -->
					<div
						class="rounded-2xl border p-5
						{autoCategory === 'ineligible' ? 'border-danger/20 bg-danger/5' : 'border-primary/20 bg-primary/5'}"
					>
						<div class="mb-1 font-chinese text-xs font-medium text-slate-500">{m.reg_combined_age()}</div>
						<div class="flex items-baseline gap-2">
							<span
								class="font-heading text-3xl
								{autoCategory === 'ineligible' ? 'text-danger' : 'text-primary'}"
							>
								{combinedAge}
							</span>
							<span class="font-chinese text-sm text-slate-500">{m.reg_age_suffix()}</span>
						</div>
						{#if autoCategory && autoCategory !== 'ineligible'}
							{#if eligibleCategories.length > 1}
								<!-- Multiple eligible categories: show selector -->
								<div class="mt-3">
									<div class="mb-1.5 font-chinese text-xs text-slate-500">{m.reg_select_category()}</div>
									<select
										class="w-full rounded-xl border border-primary/30 bg-white px-3 py-2 font-chinese text-sm font-bold text-primary focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
										value={selectedCategory?.id ?? ''}
										onchange={(e) => { selectedCategoryId = (e.target as HTMLSelectElement).value; }}
									>
										{#each eligibleCategories as cat, i}
											<option value={cat.id}>
												{getLocale() === 'zh' ? cat.name_zh : cat.name_en}{i === 0 ? ` ${m.reg_category_recommended()}` : ''}
											</option>
										{/each}
									</select>
								</div>
							{:else}
								<div class="mt-2 inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1 font-chinese text-xs font-bold text-primary">
									<Trophy class="h-3 w-3" />
									{categoryName}
								</div>
							{/if}
						{:else if autoCategory === 'ineligible'}
							<div class="mt-2 inline-flex items-center gap-1.5 rounded-full bg-danger/10 px-3 py-1 font-chinese text-xs font-bold text-danger">
								<AlertCircle class="h-3 w-3" />
								{m.reg_ineligible({ minAge: minRequiredAge })}
							</div>
						{/if}
					</div>

					<!-- Gender Type Card -->
					{#if genderType}
						<div class="rounded-2xl border border-cta/20 bg-cta/5 p-5">
							<div class="mb-1 font-chinese text-xs font-medium text-slate-500">{m.reg_match_type()}</div>
							<div class="font-heading text-3xl text-cta">
								{genderTypeLabel}
							</div>
							<div class="mt-2 font-chinese text-xs text-slate-500">
								{genderType === 'mens' ? m.reg_mens_en() : genderType === 'womens' ? m.reg_womens_en() : m.reg_mixed_en()}
							</div>
						</div>
					{/if}
				</div>
			{/if}

			<!-- Bottom Nav -->
			<div class="fixed bottom-0 left-0 right-0 border-t border-slate-200 bg-white/95 p-4 backdrop-blur-sm sm:static sm:mt-6 sm:border-0 sm:bg-transparent sm:p-0 sm:backdrop-blur-none">
				<div class="mx-auto flex max-w-2xl justify-end">
					<button
						type="button"
						onclick={() => goToStep(2)}
						disabled={!step1Valid}
						class="inline-flex w-full cursor-pointer items-center justify-center gap-2 rounded-xl px-8 py-4 font-chinese text-base font-bold text-white shadow-lg transition-all duration-200 sm:w-auto
						{step1Valid ? 'bg-cta hover:-translate-y-0.5 hover:bg-cta-hover hover:shadow-xl' : 'bg-slate-300 cursor-not-allowed shadow-none'}"
					>
						{m.reg_next()}
						<ChevronRight class="h-5 w-5" />
					</button>
				</div>
			</div>
			<!-- Spacer for fixed bottom bar on mobile -->
			<div class="h-20 sm:hidden"></div>

		<!-- ============================================ -->
		<!-- STEP 2: CONFIRMATION                        -->
		<!-- ============================================ -->
		{:else if currentStep === 2}
		<form method="POST" action="?/register" use:enhance={handleEnhance}>
			<!-- Hidden fields for form submission -->
			<input type="hidden" name="p1_firstName" value={player1.firstName} />
			<input type="hidden" name="p1_lastName" value={player1.lastName} />
			<input type="hidden" name="p1_gender" value={player1.gender} />
			<input type="hidden" name="p1_dob" value={player1.dob} />
			<input type="hidden" name="p1_email" value={player1.email} />
			<input type="hidden" name="p1_phone" value={player1.phone} />
			<input type="hidden" name="p1_wechat" value={player1.wechat} />
			<input type="hidden" name="p2_firstName" value={player2.firstName} />
			<input type="hidden" name="p2_lastName" value={player2.lastName} />
			<input type="hidden" name="p2_gender" value={player2.gender} />
			<input type="hidden" name="p2_dob" value={player2.dob} />
			<input type="hidden" name="p2_email" value={player2.email} />
			<input type="hidden" name="p2_phone" value={player2.phone} />
			<input type="hidden" name="p2_wechat" value={player2.wechat} />
			<input type="hidden" name="category_id" value={selectedCategory?.id ?? ''} />

			<!-- Server Error -->
			{#if serverError}
				<div class="mb-6 rounded-2xl border border-danger/20 bg-danger/5 p-4 text-center">
					<div class="flex items-center justify-center gap-2 font-chinese text-sm font-medium text-danger">
						<AlertCircle class="h-5 w-5" />
						{errorMessages[serverError]?.() ?? m.reg_err_unknown()}
					</div>
				</div>
			{/if}

			<!-- Category Card -->
			<div class="mb-6 rounded-2xl border border-primary/20 bg-primary/5 p-6 text-center">
				<div class="mb-1 font-chinese text-sm font-medium text-slate-500">{m.reg_auto_category()}</div>
				<div class="font-heading text-3xl text-primary-darker">{categoryName}</div>
				<div class="mt-1 font-chinese text-sm text-slate-500">{categoryNameEn} · {m.reg_combined_age_label()} {combinedAge} {m.reg_age_suffix()}</div>
			</div>

			<!-- Player Cards -->
			<div class="mb-6 space-y-4">
				<!-- Player 1 -->
				<div class="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
					<div class="flex items-center justify-between border-b border-slate-100 bg-slate-50 px-6 py-3">
						<div class="flex items-center gap-2">
							<User class="h-4 w-4 text-primary" />
							<span class="font-chinese text-sm font-bold text-slate-700">{m.reg_registrant()}</span>
						</div>
						<button
							type="button"
							onclick={() => goToStep(1)}
							class="inline-flex cursor-pointer items-center gap-1 rounded-lg px-3 py-1.5 font-chinese text-xs font-medium text-primary transition-colors duration-200 hover:bg-primary/10"
						>
							<Pencil class="h-3 w-3" />
							{m.reg_edit()}
						</button>
					</div>
					<div class="grid grid-cols-2 gap-x-6 gap-y-3 p-6">
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_name_label()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player1.firstName} {player1.lastName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_gender_label()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player1.gender === 'male' ? m.reg_gender_male() : m.reg_gender_female()}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_age_label()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{p1Age} {m.reg_age_suffix()}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_email_label()}</div>
							<div class="truncate font-chinese text-sm font-semibold text-slate-900">{player1.email}</div>
						</div>
					</div>
				</div>

				<!-- Player 2 -->
				<div class="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
					<div class="flex items-center justify-between border-b border-slate-100 bg-slate-50 px-6 py-3">
						<div class="flex items-center gap-2">
							<Users class="h-4 w-4 text-cta" />
							<span class="font-chinese text-sm font-bold text-slate-700">{m.reg_partner()}</span>
						</div>
						<button
							type="button"
							onclick={() => goToStep(1)}
							class="inline-flex cursor-pointer items-center gap-1 rounded-lg px-3 py-1.5 font-chinese text-xs font-medium text-primary transition-colors duration-200 hover:bg-primary/10"
						>
							<Pencil class="h-3 w-3" />
							{m.reg_edit()}
						</button>
					</div>
					<div class="grid grid-cols-2 gap-x-6 gap-y-3 p-6">
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_name_label()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player2.firstName} {player2.lastName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_gender_label()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player2.gender === 'male' ? m.reg_gender_male() : m.reg_gender_female()}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_age_label()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{p2Age} {m.reg_age_suffix()}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_email_label()}</div>
							<div class="truncate font-chinese text-sm font-semibold text-slate-900">{player2.email}</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Summary Stats -->
			<div class="mb-6 grid grid-cols-3 gap-3">
				<div class="rounded-2xl border border-slate-100 bg-white p-4 text-center shadow-sm">
					<div class="mb-1 font-chinese text-xs text-slate-400">{m.reg_combined_age_label()}</div>
					<div class="font-heading text-2xl text-primary-darker">{combinedAge}</div>
				</div>
				<div class="rounded-2xl border border-slate-100 bg-white p-4 text-center shadow-sm">
					<div class="mb-1 font-chinese text-xs text-slate-400">{m.reg_match_type()}</div>
					<div class="font-heading text-2xl text-primary-darker">{genderTypeLabel}</div>
				</div>
				<div class="rounded-2xl border border-slate-100 bg-white p-4 text-center shadow-sm">
					<div class="mb-1 font-chinese text-xs text-slate-400">{m.reg_fee_label()}</div>
					<div class="font-heading text-2xl text-cta">${data.config.registration_fee * 2}</div>
					<div class="font-chinese text-xs text-slate-400">{m.reg_fee_per_person()}</div>
				</div>
			</div>

			<!-- Validation Checklist -->
			<div class="mb-6 rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
				<h3 class="mb-4 font-chinese text-sm font-bold text-slate-700">{m.reg_check_title()}</h3>
				<div class="space-y-3">
					{#each validationChecks as check}
						<div class="flex items-center gap-3">
							{#if check.passed}
								<CircleCheck class="h-5 w-5 shrink-0 text-primary" />
							{:else}
								<CircleX class="h-5 w-5 shrink-0 text-danger" />
							{/if}
							<span
								class="font-chinese text-sm
								{check.passed ? 'text-slate-700' : 'text-danger font-medium'}"
							>
								{check.label}
							</span>
						</div>
					{/each}
				</div>
			</div>

			<!-- Bottom Nav -->
			<div class="fixed bottom-0 left-0 right-0 border-t border-slate-200 bg-white/95 p-4 backdrop-blur-sm sm:static sm:mt-6 sm:border-0 sm:bg-transparent sm:p-0 sm:backdrop-blur-none">
				<div class="mx-auto flex max-w-2xl gap-3">
					<button
						type="button"
						onclick={() => goToStep(1)}
						class="inline-flex cursor-pointer items-center gap-2 rounded-xl border-2 border-slate-200 px-6 py-4 font-chinese text-base font-medium text-slate-600 transition-all duration-200 hover:border-slate-300 hover:bg-slate-50"
					>
						<ChevronLeft class="h-5 w-5" />
						{m.reg_prev()}
					</button>
					<button
						type="submit"
						disabled={!allChecksPass || submitting}
						class="inline-flex flex-1 cursor-pointer items-center justify-center gap-2 rounded-xl px-8 py-4 font-chinese text-base font-bold text-white shadow-lg transition-all duration-200
						{allChecksPass && !submitting ? 'bg-cta hover:-translate-y-0.5 hover:bg-cta-hover hover:shadow-xl' : 'bg-slate-300 cursor-not-allowed shadow-none'}"
					>
						{#if submitting}
							{m.reg_submitting()}
						{:else}
							{m.reg_submit()}
							<Check class="h-5 w-5" />
						{/if}
					</button>
				</div>
			</div>
			<!-- Spacer for fixed bottom bar on mobile -->
			<div class="h-20 sm:hidden"></div>
		</form>

		<!-- ============================================ -->
		<!-- STEP 3: SUCCESS                             -->
		<!-- ============================================ -->
		{:else if currentStep === 3}
			<div class="text-center">
				<!-- Success Icon -->
				<div class="mx-auto mb-6 flex h-24 w-24 items-center justify-center rounded-full bg-primary/10">
					<CircleCheck class="h-14 w-14 text-primary" />
				</div>

				<h2 class="mb-2 font-heading text-4xl tracking-wide text-primary-darker sm:text-5xl">
					{m.reg_success_title()}
				</h2>
				<p class="mb-8 font-chinese text-slate-500">
					{m.reg_success_subtitle()}
				</p>

				<!-- Confirmation Number -->
				<div class="mb-8 rounded-2xl border border-primary/20 bg-white p-6 shadow-sm">
					<div class="mb-1 font-chinese text-sm text-slate-500">{m.reg_confirm_number()}</div>
					<div class="flex items-center justify-center gap-3">
						<span class="font-heading text-3xl text-primary-darker sm:text-4xl">{registrationResult?.teamId ? registrationResult.teamId.replace(/-/g, '').substring(0, 8).toUpperCase() : '---'}</span>
						<button
							type="button"
							onclick={() => navigator.clipboard.writeText(registrationResult?.teamId ?? '')}
							class="cursor-pointer rounded-lg p-2 text-slate-400 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-600"
							aria-label="Copy"
						>
							<Copy class="h-5 w-5" />
						</button>
					</div>
					{#if registrationResult?.status === 'waitlist'}
						<div class="mt-3 rounded-lg bg-amber-50 p-2 font-chinese text-xs font-medium text-amber-700">
							{m.reg_waitlist_notice()}
						</div>
					{/if}
				</div>

				<!-- Registration Summary -->
				<div class="mb-8 rounded-2xl border border-slate-100 bg-white p-6 text-left shadow-sm">
					<h3 class="mb-4 font-chinese text-sm font-bold text-slate-700">{m.reg_summary_title()}</h3>
					<div class="grid grid-cols-2 gap-4">
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_summary_category()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{categoryName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_summary_type()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{genderTypeLabel}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_registrant()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player1.firstName} {player1.lastName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.reg_partner()}</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player2.firstName} {player2.lastName}</div>
						</div>
					</div>
				</div>

				<!-- E-Transfer Payment Instructions -->
				<div class="mb-8 rounded-2xl border border-cta/20 bg-cta/5 p-6 text-left">
					<div class="mb-5 flex items-center gap-2">
						<DollarSign class="h-5 w-5 text-cta" />
						<h3 class="font-chinese text-sm font-bold text-slate-700">{m.pay_title()}</h3>
					</div>

					<p class="mb-4 font-chinese text-sm text-slate-600">{m.pay_instruction()}</p>

					<!-- E-Transfer Details -->
					<div class="mb-4 space-y-3 rounded-xl bg-white p-4">
						<!-- Recipient -->
						<div class="flex items-center justify-between">
							<div>
								<div class="font-chinese text-xs text-slate-400">{m.pay_recipient()}</div>
								<div class="font-chinese text-sm font-semibold text-slate-900">{data.config.etransfer_email}</div>
							</div>
							<button
								type="button"
								onclick={() => { navigator.clipboard.writeText(data.config.etransfer_email); copiedField = 'etransfer'; setTimeout(() => copiedField = null, 2000); }}
								class="cursor-pointer rounded-lg border border-slate-200 px-3 py-1.5 font-chinese text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50"
							>
								{#if copiedField === 'etransfer'}
									<Check class="inline h-3.5 w-3.5 text-primary" /> {m.pay_copied()}
								{:else}
									<Copy class="inline h-3.5 w-3.5" /> {m.pay_copy()}
								{/if}
							</button>
						</div>

						<!-- Amount -->
						<div>
							<div class="font-chinese text-xs text-slate-400">{m.pay_amount()}</div>
							<div class="font-heading text-2xl text-primary-darker">${data.config.registration_fee * 2}.00 CAD</div>
						</div>

						<!-- Memo / Ref -->
						<div class="flex items-center justify-between">
							<div>
								<div class="font-chinese text-xs text-slate-400">{m.pay_memo()}</div>
								<div class="font-mono text-lg font-bold text-cta">{registrationResult?.teamId ? registrationResult.teamId.replace(/-/g, '').substring(0, 8).toUpperCase() : '---'}</div>
							</div>
							<button
								type="button"
								onclick={() => { navigator.clipboard.writeText(registrationResult?.teamId ? registrationResult.teamId.replace(/-/g, '').substring(0, 8).toUpperCase() : ''); copiedField = 'memo'; setTimeout(() => copiedField = null, 2000); }}
								class="cursor-pointer rounded-lg border border-slate-200 px-3 py-1.5 font-chinese text-xs font-medium text-slate-600 transition-colors hover:bg-slate-50"
							>
								{#if copiedField === 'memo'}
									<Check class="inline h-3.5 w-3.5 text-primary" /> {m.pay_copied()}
								{:else}
									<Copy class="inline h-3.5 w-3.5" /> {m.pay_copy()}
								{/if}
							</button>
						</div>
					</div>

					<!-- Warnings -->
					<div class="space-y-2 text-xs">
						<div class="flex items-start gap-2 rounded-lg bg-amber-50 p-3 font-chinese text-amber-800">
							<AlertCircle class="mt-0.5 h-4 w-4 shrink-0" />
							<span>{m.pay_memo_warning({ ref: registrationResult?.teamId ? registrationResult.teamId.replace(/-/g, '').substring(0, 8).toUpperCase() : '---' })}</span>
						</div>
						<div class="flex items-start gap-2 font-chinese text-slate-500">
							<CircleCheck class="mt-0.5 h-4 w-4 shrink-0 text-primary" />
							<span>{m.pay_auto_deposit()}</span>
						</div>
						<div class="flex items-start gap-2 font-chinese text-slate-500">
							<CircleCheck class="mt-0.5 h-4 w-4 shrink-0 text-primary" />
							<span>{m.pay_arrival()}</span>
						</div>
						<div class="flex items-start gap-2 font-chinese text-slate-500">
							<Clock class="mt-0.5 h-4 w-4 shrink-0 text-amber-500" />
							<span>{m.pay_deadline({ hours: data.config.payment_deadline_hours })}</span>
						</div>
					</div>

					<!-- Contact -->
					<div class="mt-4 border-t border-cta/10 pt-4">
						<div class="font-chinese text-xs font-medium text-slate-500">{m.pay_contact()}</div>
						<div class="mt-1 flex flex-wrap gap-3 font-chinese text-xs text-slate-600">
							<span class="flex items-center gap-1"><Phone class="h-3.5 w-3.5" /> {data.config.contact_phone}</span>
							<span class="flex items-center gap-1"><MessageCircle class="h-3.5 w-3.5" /> {data.config.contact_wechat}</span>
						</div>
					</div>
				</div>

				<!-- Action Buttons -->
				<div class="flex flex-col gap-3 sm:flex-row sm:justify-center">
					<a
						href="/teams"
						class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-xl bg-primary px-8 py-4 font-chinese text-base font-bold text-white shadow-lg transition-all duration-200 hover:-translate-y-0.5 hover:bg-primary-dark hover:shadow-xl"
					>
						<Users class="h-5 w-5" />
						{m.reg_view_teams()}
					</a>
					<a
						href="/"
						class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-xl border-2 border-slate-200 px-8 py-4 font-chinese text-base font-medium text-slate-600 transition-all duration-200 hover:border-slate-300 hover:bg-slate-50"
					>
						<Home class="h-5 w-5" />
						{m.reg_back_home()}
					</a>
				</div>
			</div>
		{/if}
	</div>
</section>
