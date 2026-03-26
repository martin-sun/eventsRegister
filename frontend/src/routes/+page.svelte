<script lang="ts">
	import {
		CalendarDays,
		MapPin,
		Trophy,
		Users,
		Target,
		Award,
		ChevronRight,
		Clock,
		Swords,
		Scale,
		Medal
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';

	let { data } = $props();

	// --- Countdown Timer ---
	let eventDate = $derived(new Date(data.config.tournament_date));

	let now = $state(new Date());
	let countdown = $derived(getCountdown(now));

	function getCountdown(current: Date) {
		const diff = eventDate.getTime() - current.getTime();
		if (diff <= 0) return { days: 0, hours: 0, minutes: 0, seconds: 0 };
		return {
			days: Math.floor(diff / (1000 * 60 * 60 * 24)),
			hours: Math.floor((diff / (1000 * 60 * 60)) % 24),
			minutes: Math.floor((diff / (1000 * 60)) % 60),
			seconds: Math.floor((diff / 1000) % 60)
		};
	}

	$effect(() => {
		const timer = setInterval(() => {
			now = new Date();
		}, 1000);
		return () => clearInterval(timer);
	});

	// --- Category descriptions keyed by slug ---
	const categoryDescriptions: Record<string, () => string> = {
		'doubles-100': () => m.category_100_desc(),
		'doubles-80': () => m.category_80_desc()
	};

	const categoryColors: Record<string, string> = {
		'doubles-100': 'primary',
		'doubles-80': 'cta'
	};

	const categoryImages: Record<string, string> = {
		'doubles-100': 'cat_over100',
		'doubles-80': 'cat_over80'
	};

	let categories = $derived(
		data.categories.map((cat) => ({
			id: cat.slug,
			name: getLocale() === 'zh' ? cat.name_zh : cat.name_en,
			nameEn: cat.name_en,
			description: categoryDescriptions[cat.slug]?.() ?? '',
			registered: cat.registered_teams,
			max: cat.max_teams,
			color: categoryColors[cat.slug] ?? 'primary',
			image: categoryImages[cat.slug] ?? 'cat_over100'
		}))
	);

	// --- Sponsors grouped by level ---
	const sponsorLevelOrder = ['title', 'diamond', 'platinum', 'gold', 'friend', 'media'] as const;

	function sponsorName(s: { name_zh: string; name_en: string }): string {
		return getLocale() === 'zh' ? s.name_zh : s.name_en;
	}

	let sponsorsByLevel = $derived(
		Object.fromEntries(
			sponsorLevelOrder.map((level) => [
				level,
				data.sponsors.filter((s) => s.level === level)
			])
		)
	);

	let highlights = $derived([
		{ icon: Target, title: m.highlight_format(), desc: m.highlight_format_desc() },
		{ icon: Award, title: m.highlight_handicap(), desc: m.highlight_handicap_desc() },
		{ icon: Trophy, title: m.highlight_prize(), desc: m.highlight_prize_desc() },
		{ icon: Users, title: m.highlight_community(), desc: m.highlight_community_desc() }
	]);

	let handicapRules = $derived([
		{ match: m.handicap_mens_vs_mixed(), points: m.handicap_points_6(), startScore: m.handicap_score_mixed_6_0(), serve: m.handicap_serve_mixed() },
		{ match: m.handicap_mixed_vs_womens(), points: m.handicap_points_6(), startScore: m.handicap_score_womens_6_0(), serve: m.handicap_serve_womens() },
		{ match: m.handicap_mens_vs_womens(), points: m.handicap_points_11(), startScore: m.handicap_score_womens_11_0(), serve: m.handicap_serve_womens() },
		{ match: m.handicap_same_gender(), points: m.handicap_points_0(), startScore: m.handicap_score_0_0(), serve: m.handicap_serve_draw() }
	]);

	let prizes = $derived([
		{ rank: `🥇 ${m.prize_champion()}`, main: '$400', consolation: '$100' },
		{ rank: `🥈 ${m.prize_runner_up()}`, main: '$300', consolation: '$80' },
		{ rank: `🥉 ${m.prize_third()}`, main: '$200', consolation: '$60' },
		{ rank: m.prize_fourth(), main: '$100', consolation: '$40' }
	]);

</script>

<svelte:head>
	<title>{m.site_title_full()}</title>
</svelte:head>

<!-- ============================================ -->
<!-- HERO SECTION                                 -->
<!-- ============================================ -->
<section class="relative overflow-hidden bg-primary-darker text-white">
	<!-- High-quality Background Image with dark overlay -->
	<div class="absolute inset-0">
		<img
			src="/images/hero_bg.png"
			alt="Badminton Championship Court"
			class="h-full w-full object-cover"
		/>
		<div class="absolute inset-0 bg-primary-darker/80 bg-gradient-to-t from-primary-darker via-primary-darker/60 to-transparent"></div>
	</div>

	<div class="relative mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-28 lg:px-8 lg:py-36">
		<div class="text-center">
			<!-- Badge -->
			<div class="mb-6 inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-2 text-sm font-medium backdrop-blur-md shadow-lg">
				<CalendarDays class="h-4 w-4 text-cta" />
				<span class="font-chinese tracking-wide">{m.hero_date_badge()}</span>
			</div>

			<!-- Exaggerated Minimalism Title -->
			<h1 class="mb-2 font-heading text-6xl font-black tracking-tight sm:text-7xl lg:text-8xl">
				{m.hero_title_line1()}
			</h1>
			<h2 class="mb-6 font-heading text-4xl font-extrabold tracking-tight text-cta drop-shadow-md sm:text-5xl lg:text-6xl">
				{m.hero_title_line2()}
			</h2>

			<!-- Subtitle -->
			<div class="mb-10 flex flex-wrap items-center justify-center gap-4 font-chinese text-base font-medium text-white/90 sm:text-lg">
				<span class="flex items-center gap-1.5">
					<MapPin class="h-5 w-5 text-sky-400" />
					Riverside Badminton & Tennis Club
				</span>
				<span class="hidden sm:inline text-white/40">·</span>
				<span class="flex items-center gap-1.5">
					<Users class="h-5 w-5 text-sky-400" />
					{m.hero_fee()}
				</span>
			</div>

			<!-- Countdown -->
			<div class="mb-12 flex items-center justify-center gap-3 sm:gap-6">
				{#each [
					{ value: countdown.days, label: m.countdown_days() },
					{ value: countdown.hours, label: m.countdown_hours() },
					{ value: countdown.minutes, label: m.countdown_minutes() },
					{ value: countdown.seconds, label: m.countdown_seconds() }
				] as unit}
					<div class="flex flex-col items-center group">
						<div class="flex h-20 w-20 items-center justify-center rounded-2xl border border-white/20 bg-white/10 font-heading text-4xl shadow-2xl backdrop-blur-md transition-all duration-300 group-hover:-translate-y-1 group-hover:bg-white/20 sm:h-24 sm:w-24 sm:text-5xl">
							{String(unit.value).padStart(2, '0')}
						</div>
						<span class="mt-3 font-chinese text-sm font-medium tracking-widest text-white/80 uppercase">{unit.label}</span>
					</div>
				{/each}
			</div>

			<!-- CTA Buttons -->
			<div class="flex flex-col items-center justify-center gap-4 sm:flex-row">
				<a
					href="/register"
					class="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-cta px-10 py-5 font-chinese text-lg font-bold text-white shadow-xl transition-all duration-300 hover:-translate-y-1 hover:bg-cta-hover hover:shadow-2xl"
				>
					{m.hero_cta()}
					<ChevronRight class="h-5 w-5" />
				</a>
				<a
					href="#rules"
					class="inline-flex cursor-pointer items-center gap-2 rounded-xl border-2 border-white/30 bg-black/20 px-10 py-5 font-chinese text-lg font-medium text-white backdrop-blur-sm transition-all duration-300 hover:border-white hover:bg-white/10"
				>
					{m.hero_learn_rules()}
				</a>
			</div>
		</div>
	</div>
</section>

<!-- ============================================ -->
<!-- CATEGORY STATS CARDS                         -->
<!-- ============================================ -->
<section class="bg-white py-16 sm:py-20">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-10 text-center">
			<h2 class="mb-2 font-heading text-3xl tracking-wide text-primary-darker sm:text-4xl">
				{m.category_title()}
			</h2>
			<p class="font-chinese text-slate-500">{m.category_subtitle()}</p>
		</div>

		<div class="mx-auto grid max-w-4xl gap-8 md:grid-cols-2">
			{#each categories as cat}
				{@const percent = Math.round((cat.registered / cat.max) * 100)}
				<div class="group cursor-pointer overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-md transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl">
					<!-- Active Image Banner -->
					<div class="relative h-48 w-full overflow-hidden sm:h-56">
						<img
							src="/images/{cat.image}.png"
							alt="{cat.name}"
							class="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
						/>
						<!-- Premium gradient overlay -->
						<div class="absolute inset-0 bg-gradient-to-t from-slate-900/80 via-transparent to-transparent"></div>
						<div class="absolute bottom-4 left-6">
							<span class="inline-flex items-center gap-1.5 rounded-full bg-black/30 px-3 py-1 text-xs font-semibold text-white backdrop-blur-md">
								<Trophy class="h-3 w-3" />
								{cat.nameEn}
							</span>
						</div>
					</div>

					<div class="p-6">
						<div class="mb-5 flex items-start justify-between">
							<div>
								<h3 class="font-chinese text-2xl font-black text-slate-900">{cat.name}</h3>
								<p class="mt-1.5 font-chinese text-sm font-medium text-slate-500">{cat.description}</p>
							</div>
						</div>

						<!-- Progress -->
						<div class="mb-5 rounded-xl bg-slate-50 p-4 border border-slate-100">
							<div class="mb-2 flex items-baseline justify-between">
								<span class="font-chinese text-sm font-semibold text-slate-600">{m.category_progress()}</span>
								<span class="font-heading text-2xl font-bold {cat.color === 'primary' ? 'text-primary' : 'text-cta'}">
									{cat.registered}<span class="text-base font-medium text-slate-400">/{cat.max}{m.category_teams_unit()}</span>
								</span>
							</div>
							<div class="h-2.5 overflow-hidden rounded-full bg-slate-200">
								<div
									class="h-full rounded-full transition-all duration-1000 ease-out {cat.color === 'primary' ? 'bg-primary' : 'bg-cta'}"
									style="width: {percent}%"
								></div>
							</div>
						</div>

						<a
							href="/teams"
							class="inline-flex items-center gap-1 font-chinese text-sm font-bold {cat.color === 'primary' ? 'text-primary' : 'text-cta'} transition-colors duration-200 group-hover:text-primary-dark"
						>
							{m.category_view_details()}
							<ChevronRight class="h-4 w-4 transition-transform duration-200 group-hover:translate-x-1" />
						</a>
					</div>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- ============================================ -->
<!-- EVENT HIGHLIGHTS                             -->
<!-- ============================================ -->
<section class="bg-surface py-16 sm:py-20">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-10 text-center">
			<h2 class="mb-2 font-heading text-3xl tracking-wide text-primary-darker sm:text-4xl">
				{m.highlight_title()}
			</h2>
			<p class="font-chinese text-slate-500">{m.highlight_subtitle()}</p>
		</div>

		<div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
			{#each highlights as item}
				<div class="rounded-2xl bg-white p-6 shadow-sm transition-all duration-200 hover:-translate-y-1 hover:shadow-md">
					<div class="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 text-primary">
						<item.icon class="h-6 w-6" />
					</div>
					<h3 class="mb-1 font-chinese text-lg font-bold text-slate-900">{item.title}</h3>
					<p class="font-chinese text-sm text-slate-500">{item.desc}</p>
				</div>
			{/each}
		</div>
	</div>
</section>

<!-- ============================================ -->
<!-- KEY INFO / VENUE SECTION                     -->
<!-- ============================================ -->
<section class="bg-primary px-4 py-8 sm:py-12 lg:px-8">
	<div class="mx-auto max-w-7xl overflow-hidden rounded-3xl bg-primary-darker shadow-2xl">
		<div class="grid lg:grid-cols-2">

			<!-- Image half -->
			<div class="relative h-64 lg:h-auto">
				<img
					src="/images/venue.png"
					alt="Riverside Badminton & Tennis Club"
					class="absolute inset-0 h-full w-full object-cover"
				/>
				<div class="absolute inset-0 bg-primary-darker/60 mix-blend-multiply lg:hidden"></div>
			</div>

			<!-- Info half -->
			<div class="flex flex-col justify-center p-8 sm:p-12 lg:p-16">
				<h3 class="mb-8 font-heading text-3xl font-bold text-white sm:text-4xl">{m.venue_title()}</h3>

				<div class="flex flex-col gap-8">
					<div class="flex items-start gap-5 group">
						<div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-cta transition-colors duration-300 group-hover:bg-white/20">
							<CalendarDays class="h-7 w-7" />
						</div>
						<div>
							<div class="mb-1 font-chinese text-sm font-medium tracking-wide text-white/60">{m.venue_date_label()}</div>
							<div class="font-chinese text-xl font-bold text-white">{m.venue_date_value()} <span class="text-white/80 font-normal ml-1">{m.venue_date_day()}</span></div>
						</div>
					</div>

					<div class="flex items-start gap-5 group">
						<div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-cta transition-colors duration-300 group-hover:bg-white/20">
							<Clock class="h-7 w-7" />
						</div>
						<div>
							<div class="mb-1 font-chinese text-sm font-medium tracking-wide text-white/60">{m.venue_time_label()}</div>
							<div class="font-chinese text-xl font-bold text-white">{m.venue_time_value()} <span class="text-white/80 font-normal ml-1">{m.venue_time_note()}</span></div>
						</div>
					</div>

					<div class="flex items-start gap-5 group">
						<div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-cta transition-colors duration-300 group-hover:bg-white/20">
							<MapPin class="h-7 w-7" />
						</div>
						<div>
							<div class="mb-1 font-chinese text-sm font-medium tracking-wide text-white/60">{m.venue_location_label()}</div>
							<div class="font-chinese text-xl font-bold text-white leading-tight">Riverside Badminton <br/>& Tennis Club</div>
							<a href="/map" class="mt-2 inline-flex border-b border-cta/30 pb-0.5 font-chinese text-sm font-medium text-cta transition-colors hover:border-cta hover:text-cta-hover">
								{m.venue_map_link()}
							</a>
						</div>
					</div>
				</div>
			</div>

		</div>
	</div>
</section>

<!-- ============================================ -->
<!-- RULES SECTION                                -->
<!-- ============================================ -->
<section id="rules" class="scroll-mt-20 bg-white py-16 sm:py-20">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-10 text-center">
			<h2 class="mb-2 font-heading text-3xl tracking-wide text-primary-darker sm:text-4xl">
				{m.rules_title()}
			</h2>
			<p class="font-chinese text-slate-500">{m.rules_subtitle()}</p>
		</div>

		<!-- Format + Handicap + Prizes - 3 column grid -->
		<div class="grid gap-8 lg:grid-cols-3">

			<!-- Format Card -->
			<div class="rounded-2xl border border-slate-100 bg-surface p-6 shadow-sm">
				<div class="mb-4 flex items-center gap-3">
					<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
						<Swords class="h-5 w-5" />
					</div>
					<h3 class="font-chinese text-lg font-bold text-slate-900">{m.rules_format_title()}</h3>
				</div>
				<ul class="space-y-3 font-chinese text-sm text-slate-600">
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span><strong class="text-slate-800">{m.rules_format_1()}</strong>{m.rules_format_1_detail()}</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span>{m.rules_format_2()}</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span><strong class="text-slate-800">{m.rules_format_3_label()}</strong>{m.rules_format_3()}</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span><strong class="text-slate-800">{m.rules_format_4_label()}</strong>{m.rules_format_4()}</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span>{m.rules_format_5()}</span>
					</li>
				</ul>
			</div>

			<!-- Handicap Card -->
			<div class="rounded-2xl border border-slate-100 bg-surface p-6 shadow-sm">
				<div class="mb-4 flex items-center gap-3">
					<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-cta/10 text-cta">
						<Scale class="h-5 w-5" />
					</div>
					<h3 class="font-chinese text-lg font-bold text-slate-900">{m.handicap_title()}</h3>
				</div>
				<p class="mb-4 font-chinese text-xs text-slate-500">
					{m.handicap_note()}
				</p>
				<div class="space-y-2">
					{#each handicapRules as rule}
						<div class="rounded-lg bg-white p-3 border border-slate-100">
							<div class="flex items-center justify-between">
								<span class="font-chinese text-sm font-semibold text-slate-800">{rule.match}</span>
								<span class="rounded-full bg-primary/10 px-2 py-0.5 font-chinese text-xs font-bold text-primary">
									{m.handicap_give_prefix()}{rule.points}
								</span>
							</div>
							<div class="mt-1 flex items-center justify-between font-chinese text-xs text-slate-500">
								<span>{rule.startScore}</span>
								<span>{rule.serve}</span>
							</div>
						</div>
					{/each}
				</div>
			</div>

			<!-- Prizes Card -->
			<div class="rounded-2xl border border-slate-100 bg-surface p-6 shadow-sm">
				<div class="mb-4 flex items-center gap-3">
					<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-100 text-amber-600">
						<Medal class="h-5 w-5" />
					</div>
					<h3 class="font-chinese text-lg font-bold text-slate-900">{m.prize_title()}</h3>
				</div>
				<p class="mb-4 font-chinese text-xs text-slate-500">{m.prize_subtitle()}</p>

				<!-- Prize table -->
				<div class="overflow-hidden rounded-lg border border-slate-100 bg-white">
					<table class="w-full text-left font-chinese text-sm">
						<thead>
							<tr class="border-b border-slate-100 bg-slate-50">
								<th class="px-3 py-2 text-xs font-semibold text-slate-500">{m.prize_rank()}</th>
								<th class="px-3 py-2 text-xs font-semibold text-slate-500">{m.prize_main()}</th>
								<th class="px-3 py-2 text-xs font-semibold text-slate-500">{m.prize_consolation()}</th>
							</tr>
						</thead>
						<tbody>
							{#each prizes as prize}
								<tr class="border-b border-slate-50 last:border-0">
									<td class="px-3 py-2 font-medium text-slate-800">{prize.rank}</td>
									<td class="px-3 py-2 font-bold text-primary">{prize.main}</td>
									<td class="px-3 py-2 text-slate-600">{prize.consolation}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>

				<!-- Special prizes -->
				<div class="mt-4 rounded-lg bg-amber-50 p-3 border border-amber-100">
					<p class="font-chinese text-xs font-semibold text-amber-700 mb-1">{m.prize_special_title()}</p>
					<ul class="space-y-1 font-chinese text-xs text-amber-600">
						<li>• {m.prize_oldest()}</li>
						<li>• {m.prize_best_mixed()}</li>
						<li>• {m.prize_best_womens()}</li>
					</ul>
				</div>
			</div>

		</div>
	</div>
</section>

<!-- ============================================ -->
<!-- SPONSORS SECTION                             -->
<!-- ============================================ -->
<section id="sponsors" class="scroll-mt-20 bg-surface py-16 sm:py-20">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-10 text-center">
			<h2 class="mb-2 font-heading text-3xl tracking-wide text-primary-darker sm:text-4xl">
				{m.sponsor_section_title()}
			</h2>
			<p class="font-chinese text-slate-500">{m.sponsor_section_subtitle()}</p>
		</div>

		<!-- Title Sponsor -->
		{#if sponsorsByLevel.title?.length}
			<div class="mb-10 text-center">
				<p class="mb-4 font-chinese text-xs tracking-wider text-slate-400 uppercase">{m.sponsor_title_level()}</p>
				{#each sponsorsByLevel.title as s}
					<div
						class="group inline-block rounded-2xl border-2 border-cta/20 bg-surface-warm px-12 py-8 transition-all duration-200 hover:border-cta/40 hover:shadow-md"
					>
						<div class="font-heading text-4xl tracking-wide text-primary-darker sm:text-5xl">
							{s.name_zh}
						</div>
						<div class="mt-1 font-body text-sm text-slate-400">{s.name_en}</div>
					</div>
				{/each}
			</div>
		{/if}

		<!-- Diamond Sponsors -->
		{#if sponsorsByLevel.diamond?.length}
			<div class="mb-8">
				<p class="mb-4 text-center font-chinese text-xs tracking-wider text-slate-400 uppercase">
					{m.sponsor_diamond()}
				</p>
				<div class="flex flex-wrap items-center justify-center gap-6">
					{#each sponsorsByLevel.diamond as s}
						<div class="rounded-xl border border-slate-100 bg-slate-50 px-8 py-4 font-chinese text-base font-medium text-slate-600 transition-all duration-200 hover:border-primary/20 hover:shadow-sm">
							{sponsorName(s)}
						</div>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Gold Sponsors -->
		{#if sponsorsByLevel.gold?.length}
			<div class="mb-8">
				<p class="mb-4 text-center font-chinese text-xs tracking-wider text-slate-400 uppercase">
					{m.sponsor_gold()}
				</p>
				<div class="flex flex-wrap items-center justify-center gap-4">
					{#each sponsorsByLevel.gold as s}
						<div class="rounded-lg border border-slate-100 px-6 py-3 font-chinese text-sm text-slate-500 transition-all duration-200 hover:border-primary/20 hover:shadow-sm">
							{sponsorName(s)}
						</div>
					{/each}
				</div>
			</div>
		{/if}

		<!-- Media / Other Sponsors -->
		{#if sponsorsByLevel.media?.length || sponsorsByLevel.friend?.length}
			<div>
				<div class="flex flex-wrap items-center justify-center gap-4">
					{#each [...(sponsorsByLevel.media ?? []), ...(sponsorsByLevel.friend ?? [])] as s}
						<div class="rounded-lg border border-slate-100 px-6 py-3 font-chinese text-sm text-slate-500 transition-all duration-200 hover:border-primary/20 hover:shadow-sm">
							{sponsorName(s)}
						</div>
					{/each}
				</div>
			</div>
		{/if}

	</div>
</section>

<!-- ============================================ -->
<!-- BOTTOM CTA                                   -->
<!-- ============================================ -->
<section class="bg-primary-darker py-16 text-center text-white sm:py-20">
	<div class="mx-auto max-w-2xl px-4">
		<h2 class="mb-4 font-heading text-4xl tracking-wide sm:text-5xl">{m.cta_ready()}</h2>
		<p class="mb-8 font-chinese text-lg text-white/70">
			{m.cta_desc()}
		</p>
		<a
			href="/register"
			class="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-cta px-10 py-4 font-chinese text-lg font-bold text-white shadow-lg transition-all duration-200 hover:-translate-y-0.5 hover:bg-cta-hover hover:shadow-xl"
		>
			{m.cta_register()}
			<ChevronRight class="h-5 w-5" />
		</a>
	</div>
</section>
