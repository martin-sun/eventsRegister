<script lang="ts">
	import { Users, Trophy, Filter, ChevronRight } from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';

	function localizedName(zh: string, en: string): string {
		return getLocale() === 'zh' ? zh : en;
	}

	// --- Types ---
	type GenderType = 'mens' | 'womens' | 'mixed';
	type TeamStatus = 'confirmed' | 'pending';

	interface Team {
		id: number;
		player1: { nameEn: string; nameZh?: string; gender: 'male' | 'female'; age: number };
		player2: { nameEn: string; nameZh?: string; gender: 'male' | 'female'; age: number };
		genderType: GenderType;
		combinedAge: number;
		status: TeamStatus;
		seed?: number;
		createdAt: string;
	}

	interface Category {
		id: string;
		nameZh: string;
		nameEn: string;
		slug: string;
		minAgeSum: number;
		maxTeams: number;
		teams: Team[];
	}

	// --- Mock Data ---
	const categories: Category[] = [
		{
			id: 'cat-100',
			nameZh: '双打100岁组',
			nameEn: 'Doubles 100+ Group',
			slug: 'doubles-100',
			minAgeSum: 100,
			maxTeams: 32,
			teams: [
				{
					id: 1,
					player1: { nameEn: 'Bob Chen', nameZh: '陈伟明', gender: 'male', age: 55 },
					player2: { nameEn: 'Tom Zhang', nameZh: '张建国', gender: 'male', age: 53 },
					genderType: 'mens',
					combinedAge: 108,
					status: 'confirmed',
					seed: 1,
					createdAt: '2026-02-15'
				},
				{
					id: 2,
					player1: { nameEn: 'John Wang', nameZh: '王大力', gender: 'male', age: 52 },
					player2: { nameEn: 'Mary Li', nameZh: '李美玲', gender: 'female', age: 50 },
					genderType: 'mixed',
					combinedAge: 102,
					status: 'confirmed',
					seed: 2,
					createdAt: '2026-02-18'
				},
				{
					id: 3,
					player1: { nameEn: 'David Liu', nameZh: '刘志强', gender: 'male', age: 48 },
					player2: { nameEn: 'Kevin Wu', nameZh: '吴凯文', gender: 'male', age: 52 },
					genderType: 'mens',
					combinedAge: 100,
					status: 'confirmed',
					createdAt: '2026-02-20'
				},
				{
					id: 4,
					player1: { nameEn: 'Grace Zhao', nameZh: '赵雅婷', gender: 'female', age: 51 },
					player2: { nameEn: 'Linda Huang', nameZh: '黄丽华', gender: 'female', age: 53 },
					genderType: 'womens',
					combinedAge: 104,
					status: 'confirmed',
					createdAt: '2026-02-22'
				},
				{
					id: 5,
					player1: { nameEn: 'James Xu', nameZh: '徐俊杰', gender: 'male', age: 56 },
					player2: { nameEn: 'Helen Yang', nameZh: '杨海伦', gender: 'female', age: 49 },
					genderType: 'mixed',
					combinedAge: 105,
					status: 'confirmed',
					createdAt: '2026-02-25'
				},
				{
					id: 6,
					player1: { nameEn: 'Michael Sun', nameZh: '孙明辉', gender: 'male', age: 50 },
					player2: { nameEn: 'Peter Gao', nameZh: '高鹏飞', gender: 'male', age: 54 },
					genderType: 'mens',
					combinedAge: 104,
					status: 'confirmed',
					createdAt: '2026-03-01'
				},
				{
					id: 7,
					player1: { nameEn: 'Amy Zhou', nameZh: '周敏', gender: 'female', age: 52 },
					player2: { nameEn: 'Nancy Ma', nameZh: '马楠', gender: 'female', age: 50 },
					genderType: 'womens',
					combinedAge: 102,
					status: 'confirmed',
					createdAt: '2026-03-02'
				},
				{
					id: 8,
					player1: { nameEn: 'Eric Tang', nameZh: '唐志远', gender: 'male', age: 60 },
					player2: { nameEn: 'Frank Liang', nameZh: '梁峰', gender: 'male', age: 58 },
					genderType: 'mens',
					combinedAge: 118,
					status: 'confirmed',
					createdAt: '2026-03-03'
				},
				{
					id: 9,
					player1: { nameEn: 'Steve He', nameZh: '何世杰', gender: 'male', age: 47 },
					player2: { nameEn: 'Julia Feng', nameZh: '冯佳丽', gender: 'female', age: 55 },
					genderType: 'mixed',
					combinedAge: 102,
					status: 'pending',
					createdAt: '2026-03-05'
				},
				{
					id: 10,
					player1: { nameEn: 'Ryan Ding', nameZh: '丁睿', gender: 'male', age: 51 },
					player2: { nameEn: 'Chris Pan', nameZh: '潘超', gender: 'male', age: 50 },
					genderType: 'mens',
					combinedAge: 101,
					status: 'pending',
					createdAt: '2026-03-08'
				},
				{
					id: 11,
					player1: { nameEn: 'Sophia Ren', nameZh: '任晓菲', gender: 'female', age: 48 },
					player2: { nameEn: 'Lisa Zhu', nameZh: '朱莉莎', gender: 'female', age: 53 },
					genderType: 'womens',
					combinedAge: 101,
					status: 'pending',
					createdAt: '2026-03-10'
				},
				{
					id: 12,
					player1: { nameEn: 'Leo Qian', nameZh: '钱磊', gender: 'male', age: 53 },
					player2: { nameEn: 'Diana Jiang', nameZh: '蒋黛安', gender: 'female', age: 50 },
					genderType: 'mixed',
					combinedAge: 103,
					status: 'pending',
					createdAt: '2026-03-12'
				}
			]
		},
		{
			id: 'cat-80',
			nameZh: '双打80岁组',
			nameEn: 'Doubles 80+ Group',
			slug: 'doubles-80',
			minAgeSum: 80,
			maxTeams: 32,
			teams: [
				{
					id: 13,
					player1: { nameEn: 'Alex Lin', nameZh: '林浩', gender: 'male', age: 42 },
					player2: { nameEn: 'Brian Ye', nameZh: '叶斌', gender: 'male', age: 40 },
					genderType: 'mens',
					combinedAge: 82,
					status: 'confirmed',
					seed: 1,
					createdAt: '2026-02-16'
				},
				{
					id: 14,
					player1: { nameEn: 'Jenny Cao', nameZh: '曹婧', gender: 'female', age: 38 },
					player2: { nameEn: 'Cindy Xie', nameZh: '谢芯蕊', gender: 'female', age: 44 },
					genderType: 'womens',
					combinedAge: 82,
					status: 'confirmed',
					seed: 2,
					createdAt: '2026-02-19'
				},
				{
					id: 15,
					player1: { nameEn: 'Tony Shi', nameZh: '石涛', gender: 'male', age: 43 },
					player2: { nameEn: 'Yuki Peng', nameZh: '彭雪', gender: 'female', age: 39 },
					genderType: 'mixed',
					combinedAge: 82,
					status: 'confirmed',
					createdAt: '2026-02-21'
				},
				{
					id: 16,
					player1: { nameEn: 'Mark Cheng', nameZh: '程铭', gender: 'male', age: 45 },
					player2: { nameEn: 'Jack Song', nameZh: '宋杰', gender: 'male', age: 41 },
					genderType: 'mens',
					combinedAge: 86,
					status: 'confirmed',
					createdAt: '2026-02-28'
				},
				{
					id: 17,
					player1: { nameEn: 'Vivian Luo', nameZh: '罗薇', gender: 'female', age: 37 },
					player2: { nameEn: 'Nick Wei', nameZh: '魏宁', gender: 'male', age: 44 },
					genderType: 'mixed',
					combinedAge: 81,
					status: 'confirmed',
					createdAt: '2026-03-01'
				},
				{
					id: 18,
					player1: { nameEn: 'Hugo Fan', nameZh: '范弘', gender: 'male', age: 41 },
					player2: { nameEn: 'Ivan Meng', nameZh: '孟一帆', gender: 'male', age: 43 },
					genderType: 'mens',
					combinedAge: 84,
					status: 'confirmed',
					createdAt: '2026-03-04'
				},
				{
					id: 19,
					player1: { nameEn: 'Tina Gu', nameZh: '顾婷婷', gender: 'female', age: 40 },
					player2: { nameEn: 'Sara Yao', nameZh: '姚莎', gender: 'female', age: 42 },
					genderType: 'womens',
					combinedAge: 82,
					status: 'pending',
					createdAt: '2026-03-06'
				},
				{
					id: 20,
					player1: { nameEn: 'Oscar Zhong', nameZh: '钟翱', gender: 'male', age: 39 },
					player2: { nameEn: 'Wendy Han', nameZh: '韩雯', gender: 'female', age: 42 },
					genderType: 'mixed',
					combinedAge: 81,
					status: 'pending',
					createdAt: '2026-03-09'
				}
			]
		}
	];

	// --- Filter State ---
	let activeCategory = $state<string>('all');
	let activeGenderType = $state<string>('all');
	let searchQuery = $state('');

	// --- Derived ---
	const filteredCategories = $derived(
		categories
			.filter((cat) => activeCategory === 'all' || cat.id === activeCategory)
			.map((cat) => ({
				...cat,
				teams: cat.teams.filter((team) => {
					const matchGender =
						activeGenderType === 'all' || team.genderType === activeGenderType;
					const matchSearch =
						!searchQuery ||
						team.player1.nameEn.toLowerCase().includes(searchQuery.toLowerCase()) ||
						team.player2.nameEn.toLowerCase().includes(searchQuery.toLowerCase()) ||
						(team.player1.nameZh && team.player1.nameZh.includes(searchQuery)) ||
						(team.player2.nameZh && team.player2.nameZh.includes(searchQuery));
					return matchGender && matchSearch;
				})
			}))
	);

	const totalTeams = $derived(categories.reduce((sum, cat) => sum + cat.teams.length, 0));
	const totalSlots = $derived(categories.reduce((sum, cat) => sum + cat.maxTeams, 0));

	// --- Helpers ---
	let genderTypeLabels = $derived<Record<GenderType, { label: string; color: string; bg: string }>>({
		mens: { label: m.reg_mens(), color: 'text-blue-700', bg: 'bg-blue-50 border-blue-200' },
		womens: { label: m.reg_womens(), color: 'text-pink-700', bg: 'bg-pink-50 border-pink-200' },
		mixed: { label: m.reg_mixed(), color: 'text-violet-700', bg: 'bg-violet-50 border-violet-200' }
	});

	function maskName(nameEn: string, nameZh?: string): { en: string; zh: string } {
		const parts = nameEn.split(' ');
		const maskedEn =
			parts.length >= 2
				? `${parts[0]} ${parts[parts.length - 1][0]}.`
				: `${nameEn[0]}***`;
		const maskedZh = nameZh ? `${nameZh[0]}${'*'.repeat(nameZh.length - 1)}` : '';
		return { en: maskedEn, zh: maskedZh };
	}
</script>

<svelte:head>
	<title>{m.teams_page_title()}</title>
</svelte:head>

<!-- ============================================ -->
<!-- PAGE HEADER                                   -->
<!-- ============================================ -->
<section class="bg-primary-darker pt-24 pb-12 text-white sm:pt-28 sm:pb-16">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="text-center">
			<h1 class="mb-3 font-heading text-4xl tracking-wide sm:text-5xl">{m.teams_title()}</h1>
			<p class="mx-auto max-w-2xl font-chinese text-base text-white/70">
				{m.teams_subtitle()}
			</p>
		</div>

		<!-- Stats bar -->
		<div class="mx-auto mt-8 flex max-w-lg items-center justify-center gap-8 sm:gap-12">
			{#each categories as cat}
				{@const count = cat.teams.length}
				<div class="text-center">
					<div class="font-heading text-4xl sm:text-5xl">
						{count}<span class="text-xl text-white/50">/{cat.maxTeams}</span>
					</div>
					<div class="mt-1 font-chinese text-sm font-medium text-white/80">{localizedName(cat.nameZh, cat.nameEn)}</div>
				</div>
			{/each}
			<div class="h-12 w-px bg-white/20"></div>
			<div class="text-center">
				<div class="font-heading text-4xl sm:text-5xl">
					{totalTeams}<span class="text-xl text-white/50">/{totalSlots}</span>
				</div>
				<div class="mt-1 font-chinese text-sm font-medium text-white/80">{m.teams_total()}</div>
			</div>
		</div>
	</div>
</section>

<!-- ============================================ -->
<!-- FILTERS                                       -->
<!-- ============================================ -->
<section class="sticky top-[60px] z-40 border-b border-slate-200 bg-white/95 shadow-sm backdrop-blur-sm">
	<div class="mx-auto max-w-7xl px-4 py-3 sm:px-6 lg:px-8">
		<div class="flex flex-wrap items-center gap-3">
			<Filter class="hidden h-5 w-5 text-slate-400 sm:block" />

			<!-- Category tabs -->
			<div class="flex items-center gap-2">
				<span class="font-chinese text-xs font-medium text-slate-400">{m.teams_filter_category()}</span>
				<div class="flex rounded-lg border border-slate-200 bg-slate-50 p-0.5">
					<button
						type="button"
						class="cursor-pointer rounded-md px-3 py-1.5 font-chinese text-xs font-medium transition-all {activeCategory === 'all' ? 'bg-white text-primary shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
						onclick={() => (activeCategory = 'all')}
					>
						{m.teams_filter_all()}
					</button>
					{#each categories as cat}
						<button
							type="button"
							class="cursor-pointer rounded-md px-3 py-1.5 font-chinese text-xs font-medium transition-all {activeCategory === cat.id ? 'bg-white text-primary shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
							onclick={() => (activeCategory = cat.id)}
						>
							{localizedName(cat.nameZh, cat.nameEn)}
						</button>
					{/each}
				</div>
			</div>

			<div class="h-5 w-px bg-slate-200 hidden sm:block"></div>

			<!-- Gender type tabs -->
			<div class="flex items-center gap-2">
				<span class="font-chinese text-xs font-medium text-slate-400">{m.teams_filter_type()}</span>
				<div class="flex rounded-lg border border-slate-200 bg-slate-50 p-0.5">
					<button
						type="button"
						class="cursor-pointer rounded-md px-3 py-1.5 font-chinese text-xs font-medium transition-all {activeGenderType === 'all' ? 'bg-white text-primary shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
						onclick={() => (activeGenderType = 'all')}
					>
						{m.teams_filter_all()}
					</button>
					{#each Object.entries(genderTypeLabels) as [key, label]}
						<button
							type="button"
							class="cursor-pointer rounded-md px-3 py-1.5 font-chinese text-xs font-medium transition-all {activeGenderType === key ? 'bg-white text-primary shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
							onclick={() => (activeGenderType = key)}
						>
							{label.label}
						</button>
					{/each}
				</div>
			</div>

			<div class="h-5 w-px bg-slate-200 hidden sm:block"></div>

			<!-- Search -->
			<input
				type="text"
				placeholder={m.teams_search_placeholder()}
				class="rounded-lg border border-slate-200 bg-slate-50 px-3 py-1.5 font-chinese text-xs text-slate-700 placeholder:text-slate-400 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none w-40"
				bind:value={searchQuery}
			/>
		</div>
	</div>
</section>

<!-- ============================================ -->
<!-- TEAM LISTS                                    -->
<!-- ============================================ -->
<section class="bg-surface py-10 sm:py-14">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		{#each filteredCategories as cat}
			{@const confirmed = cat.teams.filter((t) => t.status === 'confirmed').length}
			{@const pending = cat.teams.filter((t) => t.status === 'pending').length}

			<div class="mb-12 last:mb-0">
				<!-- Category header -->
				<div class="mb-5 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
					<div class="flex items-center gap-3">
						<div class="flex h-10 w-10 items-center justify-center rounded-xl {cat.slug === 'doubles-100' ? 'bg-primary/10 text-primary' : 'bg-cta/10 text-cta'}">
							<Trophy class="h-5 w-5" />
						</div>
						<div>
							<h2 class="font-chinese text-xl font-bold text-slate-900">{cat.nameZh}</h2>
							<p class="font-body text-xs text-slate-500">{cat.nameEn}</p>
						</div>
					</div>
					<div class="flex items-center gap-4 font-chinese text-sm text-slate-500">
						<span><span class="font-bold text-emerald-600">{confirmed}</span> {m.teams_confirmed()}</span>
						{#if pending > 0}
							<span><span class="font-bold text-amber-600">{pending}</span> {m.teams_pending()}</span>
						{/if}
						<span class="text-slate-300">|</span>
						<span><span class="font-bold text-slate-700">{cat.teams.length}</span>/{cat.maxTeams} {m.teams_pairs_unit()}</span>
					</div>
				</div>

				<!-- Progress bar -->
				<div class="mb-6 h-2 overflow-hidden rounded-full bg-slate-200">
					<div
						class="h-full rounded-full transition-all duration-700 {cat.slug === 'doubles-100' ? 'bg-primary' : 'bg-cta'}"
						style="width: {Math.round((cat.teams.length / cat.maxTeams) * 100)}%"
					></div>
				</div>

				<!-- Teams table (desktop) / cards (mobile) -->
				{#if cat.teams.length > 0}
					<!-- Desktop table -->
					<div class="hidden overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm sm:block">
						<table class="w-full">
							<thead>
								<tr class="border-b border-slate-100 bg-slate-50/80">
									<th class="px-4 py-3 text-left font-chinese text-xs font-semibold tracking-wide text-slate-500">#</th>
									<th class="px-4 py-3 text-left font-chinese text-xs font-semibold tracking-wide text-slate-500">{m.teams_player1()}</th>
									<th class="px-4 py-3 text-left font-chinese text-xs font-semibold tracking-wide text-slate-500">{m.teams_player2()}</th>
									<th class="px-4 py-3 text-center font-chinese text-xs font-semibold tracking-wide text-slate-500">{m.teams_type_header()}</th>
									<th class="px-4 py-3 text-center font-chinese text-xs font-semibold tracking-wide text-slate-500">{m.teams_age_sum()}</th>
									<th class="px-4 py-3 text-center font-chinese text-xs font-semibold tracking-wide text-slate-500">{m.teams_status()}</th>
								</tr>
							</thead>
							<tbody>
								{#each cat.teams as team, i}
									{@const p1 = maskName(team.player1.nameEn, team.player1.nameZh)}
									{@const p2 = maskName(team.player2.nameEn, team.player2.nameZh)}
									{@const gtl = genderTypeLabels[team.genderType]}
									<tr class="border-b border-slate-50 transition-colors last:border-0 hover:bg-slate-50/50">
										<!-- Number -->
										<td class="px-4 py-3.5">
											<div class="flex items-center gap-2">
												{#if team.seed}
													<span class="flex h-7 w-7 items-center justify-center rounded-lg bg-amber-50 font-heading text-xs font-bold text-amber-600 border border-amber-200">
														{team.seed}
													</span>
												{:else}
													<span class="flex h-7 w-7 items-center justify-center rounded-lg bg-slate-50 font-heading text-xs font-medium text-slate-500 border border-slate-200">
														{i + 1}
													</span>
												{/if}
											</div>
										</td>
										<!-- Player 1 -->
										<td class="px-4 py-3.5">
											<div class="flex flex-col gap-0.5">
												<div class="font-body text-sm font-semibold text-slate-800">{p1.en}</div>
												{#if p1.zh}
													<div class="font-chinese text-xs text-slate-500 font-medium">{p1.zh}</div>
												{/if}
											</div>
										</td>
										<!-- Player 2 -->
										<td class="px-4 py-3.5">
											<div class="flex flex-col gap-0.5">
												<div class="font-body text-sm font-semibold text-slate-800">{p2.en}</div>
												{#if p2.zh}
													<div class="font-chinese text-xs text-slate-500 font-medium">{p2.zh}</div>
												{/if}
											</div>
										</td>
										<!-- Gender type -->
										<td class="px-4 py-3.5 text-center">
											<span class="inline-flex items-center justify-center rounded-full border px-3 py-1 font-chinese text-xs font-semibold {gtl.bg} {gtl.color}">
												{gtl.label}
											</span>
										</td>
										<!-- Combined age -->
										<td class="px-4 py-3.5 text-center">
											<span class="font-heading text-sm font-bold text-slate-700">{team.combinedAge}</span>
											<span class="font-chinese text-xs text-slate-400">{m.reg_age_suffix()}</span>
										</td>
										<!-- Status -->
										<td class="px-4 py-3.5 text-center">
											{#if team.status === 'confirmed'}
												<span class="inline-flex items-center gap-1.5 font-chinese text-xs font-medium text-emerald-600">
													<span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>
													{m.teams_confirmed()}
												</span>
											{:else}
												<span class="inline-flex items-center gap-1.5 font-chinese text-xs font-medium text-amber-600">
													<span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
													{m.teams_pending()}
												</span>
											{/if}
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>

					<!-- Mobile cards -->
					<div class="flex flex-col gap-3 sm:hidden">
						{#each cat.teams as team, i}
							{@const p1 = maskName(team.player1.nameEn, team.player1.nameZh)}
							{@const p2 = maskName(team.player2.nameEn, team.player2.nameZh)}
							{@const gtl = genderTypeLabels[team.genderType]}
							<div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
								<div class="mb-3 flex items-center justify-between">
									<div class="flex items-center gap-2">
										{#if team.seed}
											<span class="flex h-6 w-6 items-center justify-center rounded-md bg-amber-50 font-heading text-xs font-bold text-amber-600 border border-amber-200">
												{team.seed}
											</span>
										{:else}
											<span class="flex h-6 w-6 items-center justify-center rounded-md bg-slate-100 font-heading text-xs font-medium text-slate-500">
												{i + 1}
											</span>
										{/if}
										<span class="inline-flex rounded-full border px-2 py-0.5 font-chinese text-xs font-semibold {gtl.bg} {gtl.color}">
											{gtl.label}
										</span>
									</div>
									<div class="flex items-center gap-2">
										<span class="font-heading text-sm font-bold text-slate-700">{team.combinedAge}<span class="font-chinese text-xs font-normal text-slate-400">{m.reg_age_suffix()}</span></span>
										{#if team.status === 'confirmed'}
											<span class="h-2 w-2 rounded-full bg-emerald-500" title={m.teams_confirmed()}></span>
										{:else}
											<span class="h-2 w-2 rounded-full bg-amber-500" title={m.teams_pending()}></span>
										{/if}
									</div>
								</div>
								<div class="grid grid-cols-2 gap-3">
									<div>
										<div class="mb-0.5 font-chinese text-[10px] text-slate-400">{m.teams_player1()}</div>
										<div class="font-body text-sm font-semibold text-slate-800">{p1.en}</div>
										{#if p1.zh}
											<div class="font-chinese text-xs text-slate-400">{p1.zh}</div>
										{/if}
									</div>
									<div>
										<div class="mb-0.5 font-chinese text-[10px] text-slate-400">{m.teams_player2()}</div>
										<div class="font-body text-sm font-semibold text-slate-800">{p2.en}</div>
										{#if p2.zh}
											<div class="font-chinese text-xs text-slate-400">{p2.zh}</div>
										{/if}
									</div>
								</div>
							</div>
						{/each}
					</div>
				{:else}
					<div class="flex flex-col items-center justify-center rounded-2xl border border-dashed border-slate-300 bg-white/60 py-16 text-center shadow-sm">
						<div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-slate-100">
							<Users class="h-8 w-8 text-slate-400" />
						</div>
						<h3 class="mb-1 font-chinese text-base font-medium text-slate-700">{m.teams_empty_title()}</h3>
						<p class="font-chinese text-sm text-slate-500">{m.teams_empty_desc()}</p>
					</div>
				{/if}
			</div>
		{/each}
	</div>
</section>

<!-- ============================================ -->
<!-- BOTTOM CTA                                    -->
<!-- ============================================ -->
<section class="bg-primary-darker py-14 text-center text-white sm:py-16">
	<div class="mx-auto max-w-2xl px-4">
		<h2 class="mb-3 font-heading text-3xl tracking-wide sm:text-4xl">{m.teams_cta_title()}</h2>
		<p class="mb-6 font-chinese text-base text-white/70">
			{m.teams_cta_desc()}
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
