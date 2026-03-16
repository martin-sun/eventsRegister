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
		Heart
	} from 'lucide-svelte';

	// --- Constants ---
	const TOURNAMENT_DATE = new Date('2026-05-24');
	const MIN_INDIVIDUAL_AGE = 35;

	// --- State ---
	let currentStep = $state(1);

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

	let autoCategory = $derived.by(() => {
		if (combinedAge === null) return null;
		if (combinedAge >= 100) return 'over100';
		if (combinedAge >= 80) return 'over80';
		return 'ineligible';
	});

	let categoryName = $derived.by(() => {
		if (autoCategory === 'over100') return '双打100岁组';
		if (autoCategory === 'over80') return '双打80岁组';
		if (autoCategory === 'ineligible') return '不符合参赛条件';
		return '';
	});

	let categoryNameEn = $derived.by(() => {
		if (autoCategory === 'over100') return 'Doubles 100+ Group';
		if (autoCategory === 'over80') return 'Doubles 80+ Group';
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
		if (genderType === 'mens') return '男双';
		if (genderType === 'womens') return '女双';
		if (genderType === 'mixed') return '混双';
		return '';
	});

	// --- Validation ---
	function isValidEmail(email: string): boolean {
		return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
	}

	let p1Errors = $derived.by(() => {
		const errors: Record<string, string> = {};
		if (touched1.firstName && !player1.firstName.trim()) errors.firstName = '请填写名字';
		if (touched1.lastName && !player1.lastName.trim()) errors.lastName = '请填写姓氏';
		if (touched1.gender && !player1.gender) errors.gender = '请选择性别';
		if (touched1.dob) {
			if (!player1.dob) {
				errors.dob = '请填写出生日期';
			} else if (p1Age !== null && p1Age < MIN_INDIVIDUAL_AGE) {
				errors.dob = `参赛者须年满${MIN_INDIVIDUAL_AGE}岁（当前${p1Age}岁）`;
			}
		}
		if (touched1.email) {
			if (!player1.email.trim()) {
				errors.email = '请填写电子邮箱';
			} else if (!isValidEmail(player1.email)) {
				errors.email = '邮箱格式不正确';
			}
		}
		return errors;
	});

	let p2Errors = $derived.by(() => {
		const errors: Record<string, string> = {};
		if (touched2.firstName && !player2.firstName.trim()) errors.firstName = '请填写名字';
		if (touched2.lastName && !player2.lastName.trim()) errors.lastName = '请填写姓氏';
		if (touched2.gender && !player2.gender) errors.gender = '请选择性别';
		if (touched2.dob) {
			if (!player2.dob) {
				errors.dob = '请填写出生日期';
			} else if (p2Age !== null && p2Age < MIN_INDIVIDUAL_AGE) {
				errors.dob = `参赛者须年满${MIN_INDIVIDUAL_AGE}岁（当前${p2Age}岁）`;
			}
		}
		if (touched2.email) {
			if (!player2.email.trim()) {
				errors.email = '请填写电子邮箱';
			} else if (!isValidEmail(player2.email)) {
				errors.email = '邮箱格式不正确';
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
			autoCategory !== null &&
			autoCategory !== 'ineligible'
	);

	let validationChecks = $derived.by(() => [
		{
			label: '两位选手均年满35岁',
			passed: p1Age !== null && p1Age >= 35 && p2Age !== null && p2Age >= 35
		},
		{
			label: '组合年龄符合参赛要求',
			passed: autoCategory !== null && autoCategory !== 'ineligible'
		},
		{
			label: '必填信息已完整',
			passed: isPlayerValid(player1, p1Age) && isPlayerValid(player2, p2Age)
		},
		{
			label: '比赛类型已确认',
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

	function handleSubmit() {
		if (allChecksPass) {
			currentStep = 3;
			window.scrollTo({ top: 0, behavior: 'smooth' });
		}
	}

	// --- Step labels ---
	const steps = [
		{ num: 1, label: '填写信息' },
		{ num: 2, label: '确认' },
		{ num: 3, label: '完成' }
	];
</script>

<svelte:head>
	<title>报名参赛 - 萨斯卡通羽毛球双打锦标赛 2026</title>
</svelte:head>

<!-- ============================================ -->
<!-- PAGE CONTAINER                               -->
<!-- ============================================ -->
<section class="min-h-screen bg-surface py-8 sm:py-12">
	<div class="mx-auto max-w-2xl px-4">
		<!-- Page Title -->
		<div class="mb-8 text-center">
			<h1 class="mb-2 font-heading text-4xl tracking-wide text-primary-darker sm:text-5xl">
				赛事报名
			</h1>
			<p class="font-chinese text-slate-500">填写两位选手信息，系统自动分配组别</p>
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
						<h2 class="font-chinese text-lg font-bold text-slate-900">报名人 (Player 1)</h2>
					</div>
				</div>

				<div class="space-y-5 p-6">
					<!-- Name Row -->
					<div class="grid grid-cols-2 gap-4">
						<div>
							<label for="p1-first" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								First Name / 名 <span class="text-danger">*</span>
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
								Last Name / 姓 <span class="text-danger">*</span>
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
							性别 <span class="text-danger">*</span>
						</legend>
						<div class="flex gap-3">
							<button
								type="button"
								onclick={() => { player1.gender = 'male'; touched1.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player1.gender === 'male' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								男
							</button>
							<button
								type="button"
								onclick={() => { player1.gender = 'female'; touched1.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player1.gender === 'female' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								女
							</button>
						</div>
						{#if p1Errors.gender}
							<p class="mt-1 font-chinese text-xs text-danger">{p1Errors.gender}</p>
						{/if}
					</fieldset>

					<!-- DOB -->
					<div>
						<label for="p1-dob" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							出生日期 <span class="text-danger">*</span>
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
									{p1Age}岁
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
							电子邮箱 <span class="text-danger">*</span>
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
							手机号 <span class="text-slate-400 font-normal">(选填)</span>
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
							微信号 <span class="text-slate-400 font-normal">(选填)</span>
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
						<h2 class="font-chinese text-lg font-bold text-slate-900">搭档 (Player 2)</h2>
					</div>
				</div>

				<div class="space-y-5 p-6">
					<!-- Name Row -->
					<div class="grid grid-cols-2 gap-4">
						<div>
							<label for="p2-first" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
								First Name / 名 <span class="text-danger">*</span>
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
								Last Name / 姓 <span class="text-danger">*</span>
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
							性别 <span class="text-danger">*</span>
						</legend>
						<div class="flex gap-3">
							<button
								type="button"
								onclick={() => { player2.gender = 'male'; touched2.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player2.gender === 'male' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								男
							</button>
							<button
								type="button"
								onclick={() => { player2.gender = 'female'; touched2.gender = true; }}
								class="flex-1 cursor-pointer rounded-xl border-2 px-4 py-3 font-chinese text-sm font-semibold transition-all duration-200
								{player2.gender === 'female' ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-500 hover:border-slate-300'}"
							>
								女
							</button>
						</div>
						{#if p2Errors.gender}
							<p class="mt-1 font-chinese text-xs text-danger">{p2Errors.gender}</p>
						{/if}
					</fieldset>

					<!-- DOB -->
					<div>
						<label for="p2-dob" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
							出生日期 <span class="text-danger">*</span>
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
									{p2Age}岁
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
							电子邮箱 <span class="text-danger">*</span>
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
							手机号 <span class="text-slate-400 font-normal">(选填)</span>
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
							微信号 <span class="text-slate-400 font-normal">(选填)</span>
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
						<div class="mb-1 font-chinese text-xs font-medium text-slate-500">组合年龄</div>
						<div class="flex items-baseline gap-2">
							<span
								class="font-heading text-3xl
								{autoCategory === 'ineligible' ? 'text-danger' : 'text-primary'}"
							>
								{combinedAge}
							</span>
							<span class="font-chinese text-sm text-slate-500">岁</span>
						</div>
						{#if autoCategory && autoCategory !== 'ineligible'}
							<div class="mt-2 inline-flex items-center gap-1.5 rounded-full bg-primary/10 px-3 py-1 font-chinese text-xs font-bold text-primary">
								<Trophy class="h-3 w-3" />
								{categoryName}
							</div>
						{:else if autoCategory === 'ineligible'}
							<div class="mt-2 inline-flex items-center gap-1.5 rounded-full bg-danger/10 px-3 py-1 font-chinese text-xs font-bold text-danger">
								<AlertCircle class="h-3 w-3" />
								不符合参赛条件（需 ≥ 80岁）
							</div>
						{/if}
					</div>

					<!-- Gender Type Card -->
					{#if genderType}
						<div class="rounded-2xl border border-cta/20 bg-cta/5 p-5">
							<div class="mb-1 font-chinese text-xs font-medium text-slate-500">比赛类型</div>
							<div class="font-heading text-3xl text-cta">
								{genderTypeLabel}
							</div>
							<div class="mt-2 font-chinese text-xs text-slate-500">
								{genderType === 'mens' ? 'Men\'s Doubles' : genderType === 'womens' ? 'Women\'s Doubles' : 'Mixed Doubles'}
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
						下一步
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

			<!-- Category Card -->
			<div class="mb-6 rounded-2xl border border-primary/20 bg-primary/5 p-6 text-center">
				<div class="mb-1 font-chinese text-sm font-medium text-slate-500">自动分配组别</div>
				<div class="font-heading text-3xl text-primary-darker">{categoryName}</div>
				<div class="mt-1 font-chinese text-sm text-slate-500">{categoryNameEn} · 组合年龄 {combinedAge} 岁</div>
			</div>

			<!-- Player Cards -->
			<div class="mb-6 space-y-4">
				<!-- Player 1 -->
				<div class="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
					<div class="flex items-center justify-between border-b border-slate-100 bg-slate-50 px-6 py-3">
						<div class="flex items-center gap-2">
							<User class="h-4 w-4 text-primary" />
							<span class="font-chinese text-sm font-bold text-slate-700">报名人</span>
						</div>
						<button
							type="button"
							onclick={() => goToStep(1)}
							class="inline-flex cursor-pointer items-center gap-1 rounded-lg px-3 py-1.5 font-chinese text-xs font-medium text-primary transition-colors duration-200 hover:bg-primary/10"
						>
							<Pencil class="h-3 w-3" />
							编辑
						</button>
					</div>
					<div class="grid grid-cols-2 gap-x-6 gap-y-3 p-6">
						<div>
							<div class="font-chinese text-xs text-slate-400">姓名</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player1.firstName} {player1.lastName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">性别</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player1.gender === 'male' ? '男' : '女'}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">年龄</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{p1Age} 岁</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">邮箱</div>
							<div class="truncate font-chinese text-sm font-semibold text-slate-900">{player1.email}</div>
						</div>
					</div>
				</div>

				<!-- Player 2 -->
				<div class="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm">
					<div class="flex items-center justify-between border-b border-slate-100 bg-slate-50 px-6 py-3">
						<div class="flex items-center gap-2">
							<Users class="h-4 w-4 text-cta" />
							<span class="font-chinese text-sm font-bold text-slate-700">搭档</span>
						</div>
						<button
							type="button"
							onclick={() => goToStep(1)}
							class="inline-flex cursor-pointer items-center gap-1 rounded-lg px-3 py-1.5 font-chinese text-xs font-medium text-primary transition-colors duration-200 hover:bg-primary/10"
						>
							<Pencil class="h-3 w-3" />
							编辑
						</button>
					</div>
					<div class="grid grid-cols-2 gap-x-6 gap-y-3 p-6">
						<div>
							<div class="font-chinese text-xs text-slate-400">姓名</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player2.firstName} {player2.lastName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">性别</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player2.gender === 'male' ? '男' : '女'}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">年龄</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{p2Age} 岁</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">邮箱</div>
							<div class="truncate font-chinese text-sm font-semibold text-slate-900">{player2.email}</div>
						</div>
					</div>
				</div>
			</div>

			<!-- Summary Stats -->
			<div class="mb-6 grid grid-cols-3 gap-3">
				<div class="rounded-2xl border border-slate-100 bg-white p-4 text-center shadow-sm">
					<div class="mb-1 font-chinese text-xs text-slate-400">组合年龄</div>
					<div class="font-heading text-2xl text-primary-darker">{combinedAge}</div>
				</div>
				<div class="rounded-2xl border border-slate-100 bg-white p-4 text-center shadow-sm">
					<div class="mb-1 font-chinese text-xs text-slate-400">比赛类型</div>
					<div class="font-heading text-2xl text-primary-darker">{genderTypeLabel}</div>
				</div>
				<div class="rounded-2xl border border-slate-100 bg-white p-4 text-center shadow-sm">
					<div class="mb-1 font-chinese text-xs text-slate-400">报名费</div>
					<div class="font-heading text-2xl text-cta">$60</div>
					<div class="font-chinese text-xs text-slate-400">$30/人</div>
				</div>
			</div>

			<!-- Validation Checklist -->
			<div class="mb-6 rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
				<h3 class="mb-4 font-chinese text-sm font-bold text-slate-700">验证清单</h3>
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
						上一步
					</button>
					<button
						type="button"
						onclick={handleSubmit}
						disabled={!allChecksPass}
						class="inline-flex flex-1 cursor-pointer items-center justify-center gap-2 rounded-xl px-8 py-4 font-chinese text-base font-bold text-white shadow-lg transition-all duration-200
						{allChecksPass ? 'bg-cta hover:-translate-y-0.5 hover:bg-cta-hover hover:shadow-xl' : 'bg-slate-300 cursor-not-allowed shadow-none'}"
					>
						确认提交
						<Check class="h-5 w-5" />
					</button>
				</div>
			</div>
			<!-- Spacer for fixed bottom bar on mobile -->
			<div class="h-20 sm:hidden"></div>

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
					报名成功！
				</h2>
				<p class="mb-8 font-chinese text-slate-500">
					您的报名信息已提交，请按以下方式完成缴费
				</p>

				<!-- Confirmation Number -->
				<div class="mb-8 rounded-2xl border border-primary/20 bg-white p-6 shadow-sm">
					<div class="mb-1 font-chinese text-sm text-slate-500">确认号 / Confirmation Number</div>
					<div class="flex items-center justify-center gap-3">
						<span class="font-heading text-4xl text-primary-darker sm:text-5xl">#2026-0012</span>
						<button
							type="button"
							onclick={() => navigator.clipboard.writeText('2026-0012')}
							class="cursor-pointer rounded-lg p-2 text-slate-400 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-600"
							aria-label="复制确认号"
						>
							<Copy class="h-5 w-5" />
						</button>
					</div>
				</div>

				<!-- Registration Summary -->
				<div class="mb-8 rounded-2xl border border-slate-100 bg-white p-6 text-left shadow-sm">
					<h3 class="mb-4 font-chinese text-sm font-bold text-slate-700">报名摘要</h3>
					<div class="grid grid-cols-2 gap-4">
						<div>
							<div class="font-chinese text-xs text-slate-400">组别</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{categoryName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">类型</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{genderTypeLabel}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">报名人</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player1.firstName} {player1.lastName}</div>
						</div>
						<div>
							<div class="font-chinese text-xs text-slate-400">搭档</div>
							<div class="font-chinese text-sm font-semibold text-slate-900">{player2.firstName} {player2.lastName}</div>
						</div>
					</div>
				</div>

				<!-- Payment Methods -->
				<div class="mb-8 rounded-2xl border border-cta/20 bg-cta/5 p-6 text-left">
					<div class="mb-4 flex items-center gap-2">
						<DollarSign class="h-5 w-5 text-cta" />
						<h3 class="font-chinese text-sm font-bold text-slate-700">缴费方式（$60/队）</h3>
					</div>
					<div class="space-y-3">
						<div class="flex items-start gap-3">
							<div class="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-white text-xs font-bold text-cta shadow-sm">1</div>
							<div>
								<div class="font-chinese text-sm font-semibold text-slate-900">e-Transfer</div>
								<div class="font-chinese text-xs text-slate-500">发送至 badminton@saskatoon.example</div>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<div class="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-white text-xs font-bold text-cta shadow-sm">2</div>
							<div>
								<div class="font-chinese text-sm font-semibold text-slate-900">现场现金</div>
								<div class="font-chinese text-xs text-slate-500">比赛当天现场缴纳</div>
							</div>
						</div>
						<div class="flex items-start gap-3">
							<div class="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-white text-xs font-bold text-cta shadow-sm">3</div>
							<div>
								<div class="font-chinese text-sm font-semibold text-slate-900">微信支付</div>
								<div class="font-chinese text-xs text-slate-500">联系组委会获取收款码</div>
							</div>
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
						查看参赛队伍
					</a>
					<a
						href="/"
						class="inline-flex cursor-pointer items-center justify-center gap-2 rounded-xl border-2 border-slate-200 px-8 py-4 font-chinese text-base font-medium text-slate-600 transition-all duration-200 hover:border-slate-300 hover:bg-slate-50"
					>
						<Home class="h-5 w-5" />
						返回首页
					</a>
				</div>
			</div>
		{/if}
	</div>
</section>
