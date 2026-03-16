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

	// --- Countdown Timer ---
	const eventDate = new Date('2026-05-24T09:30:00');

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

	// --- Mock Data ---
	const categories = [
		{
			id: 'over100',
			name: '双打100岁组',
			nameEn: 'Doubles 100+ Group',
			description: '两位选手年龄之和 ≥ 100岁',
			registered: 12,
			max: 32,
			color: 'primary'
		},
		{
			id: 'over80',
			name: '双打80岁组',
			nameEn: 'Doubles 80+ Group',
			description: '两位选手年龄之和 ≥ 80岁',
			registered: 8,
			max: 32,
			color: 'cta'
		}
	];

	const highlights = [
		{ icon: Target, title: '3局2胜制', desc: '21分每球得分制' },
		{ icon: Award, title: '公平让分', desc: '男双/混双/女双让分机制' },
		{ icon: Trophy, title: '丰厚奖金', desc: '冠亚季军均有奖励' },
		{ icon: Users, title: '社区交流', desc: '结识更多球友' }
	];

	const handicapRules = [
		{ match: '男双 vs 混双', points: '6分', startScore: '混双 6 : 0 男双', serve: '混双先发' },
		{ match: '混双 vs 女双', points: '6分', startScore: '女双 6 : 0 混双', serve: '女双先发' },
		{ match: '男双 vs 女双', points: '11分', startScore: '女双 11 : 0 男双', serve: '女双先发' },
		{ match: '同性别对阵', points: '0分', startScore: '0 : 0', serve: '抽签决定' }
	];

	const prizes = [
		{ rank: '🥇 冠军', main: '$400', consolation: '$100' },
		{ rank: '🥈 亚军', main: '$300', consolation: '$80' },
		{ rank: '🥉 季军', main: '$200', consolation: '$60' },
		{ rank: '第4名', main: '$100', consolation: '$40' }
	];

	const sponsors = {
		title: { name: '林与唐地产', nameEn: 'Lin & Tang Realty' },
		diamond: ['赞助商 A', '赞助商 B', '赞助商 C'],
		gold: ['赞助商 D', '赞助商 E', '赞助商 F', '赞助商 G']
	};
</script>

<svelte:head>
	<title>萨斯卡通羽毛球双打锦标赛 2026</title>
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
				<span class="font-chinese tracking-wide">2026年5月24日 (周日)</span>
			</div>

			<!-- Exaggerated Minimalism Title -->
			<h1 class="mb-2 font-heading text-6xl font-black tracking-tight sm:text-7xl lg:text-8xl">
				萨斯卡通羽毛球
			</h1>
			<h2 class="mb-6 font-heading text-4xl font-extrabold tracking-tight text-cta drop-shadow-md sm:text-5xl lg:text-6xl">
				双打锦标赛
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
					报名费 $30/人
				</span>
			</div>

			<!-- Countdown -->
			<div class="mb-12 flex items-center justify-center gap-3 sm:gap-6">
				{#each [
					{ value: countdown.days, label: '天' },
					{ value: countdown.hours, label: '时' },
					{ value: countdown.minutes, label: '分' },
					{ value: countdown.seconds, label: '秒' }
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
					立即报名
					<ChevronRight class="h-5 w-5" />
				</a>
				<a
					href="#rules"
					class="inline-flex cursor-pointer items-center gap-2 rounded-xl border-2 border-white/30 bg-black/20 px-10 py-5 font-chinese text-lg font-medium text-white backdrop-blur-sm transition-all duration-300 hover:border-white hover:bg-white/10"
				>
					了解赛制
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
				比赛项目
			</h2>
			<p class="font-chinese text-slate-500">选择你的组别，与搭档一起参赛</p>
		</div>

		<div class="mx-auto grid max-w-4xl gap-8 md:grid-cols-2">
			{#each categories as cat}
				{@const percent = Math.round((cat.registered / cat.max) * 100)}
				<div class="group cursor-pointer overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-md transition-all duration-300 hover:-translate-y-2 hover:shadow-2xl">
					<!-- Active Image Banner -->
					<div class="relative h-48 w-full overflow-hidden sm:h-56">
						<img 
							src="/images/{cat.id === 'over100' ? 'cat_over100' : 'cat_over80'}.png" 
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
								<span class="font-chinese text-sm font-semibold text-slate-600">已报名进度</span>
								<span class="font-heading text-2xl font-bold {cat.color === 'primary' ? 'text-primary' : 'text-cta'}">
									{cat.registered}<span class="text-base font-medium text-slate-400">/{cat.max}对</span>
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
							查看参赛详情
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
				赛事亮点
			</h2>
			<p class="font-chinese text-slate-500">专为社区羽毛球爱好者打造的公平赛事</p>
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
				<h3 class="mb-8 font-heading text-3xl font-bold text-white sm:text-4xl">赛事信息</h3>
				
				<div class="flex flex-col gap-8">
					<div class="flex items-start gap-5 group">
						<div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-cta transition-colors duration-300 group-hover:bg-white/20">
							<CalendarDays class="h-7 w-7" />
						</div>
						<div>
							<div class="mb-1 font-chinese text-sm font-medium tracking-wide text-white/60">比赛日期</div>
							<div class="font-chinese text-xl font-bold text-white">2026年5月24日 <span class="text-white/80 font-normal ml-1">(周日)</span></div>
						</div>
					</div>
					
					<div class="flex items-start gap-5 group">
						<div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-cta transition-colors duration-300 group-hover:bg-white/20">
							<Clock class="h-7 w-7" />
						</div>
						<div>
							<div class="mb-1 font-chinese text-sm font-medium tracking-wide text-white/60">开赛时间</div>
							<div class="font-chinese text-xl font-bold text-white">上午 9:30 <span class="text-white/80 font-normal ml-1">准时开始</span></div>
						</div>
					</div>
					
					<div class="flex items-start gap-5 group">
						<div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-white/10 text-cta transition-colors duration-300 group-hover:bg-white/20">
							<MapPin class="h-7 w-7" />
						</div>
						<div>
							<div class="mb-1 font-chinese text-sm font-medium tracking-wide text-white/60">比赛地点</div>
							<div class="font-chinese text-xl font-bold text-white leading-tight">Riverside Badminton <br/>& Tennis Club</div>
							<a href="/map" class="mt-2 inline-flex border-b border-cta/30 pb-0.5 font-chinese text-sm font-medium text-cta transition-colors hover:border-cta hover:text-cta-hover">
								查看地图
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
				赛制规则
			</h2>
			<p class="font-chinese text-slate-500">公平竞技，让每一场比赛都精彩</p>
		</div>

		<!-- Format + Handicap + Prizes - 3 column grid -->
		<div class="grid gap-8 lg:grid-cols-3">

			<!-- Format Card -->
			<div class="rounded-2xl border border-slate-100 bg-surface p-6 shadow-sm">
				<div class="mb-4 flex items-center gap-3">
					<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
						<Swords class="h-5 w-5" />
					</div>
					<h3 class="font-chinese text-lg font-bold text-slate-900">比赛形式</h3>
				</div>
				<ul class="space-y-3 font-chinese text-sm text-slate-600">
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span><strong class="text-slate-800">3局2胜制</strong>，每局21分</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span>每球得分制（Rally Point）</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span><strong class="text-slate-800">正赛：</strong>单败淘汰 + 三四名决赛</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span><strong class="text-slate-800">安慰赛：</strong>首轮负者进入，同为单败淘汰</span>
					</li>
					<li class="flex items-start gap-2">
						<span class="mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary"></span>
						<span>每位选手最少两场比赛</span>
					</li>
				</ul>
			</div>

			<!-- Handicap Card -->
			<div class="rounded-2xl border border-slate-100 bg-surface p-6 shadow-sm">
				<div class="mb-4 flex items-center gap-3">
					<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-cta/10 text-cta">
						<Scale class="h-5 w-5" />
					</div>
					<h3 class="font-chinese text-lg font-bold text-slate-900">让分规则</h3>
				</div>
				<p class="mb-4 font-chinese text-xs text-slate-500">
					性别优势方让分：男双 &gt; 混双 &gt; 女双
				</p>
				<div class="space-y-2">
					{#each handicapRules as rule}
						<div class="rounded-lg bg-white p-3 border border-slate-100">
							<div class="flex items-center justify-between">
								<span class="font-chinese text-sm font-semibold text-slate-800">{rule.match}</span>
								<span class="rounded-full bg-primary/10 px-2 py-0.5 font-chinese text-xs font-bold text-primary">
									让{rule.points}
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
					<h3 class="font-chinese text-lg font-bold text-slate-900">奖金设置</h3>
				</div>
				<p class="mb-4 font-chinese text-xs text-slate-500">每组均设正赛与安慰赛奖金</p>

				<!-- Prize table -->
				<div class="overflow-hidden rounded-lg border border-slate-100 bg-white">
					<table class="w-full text-left font-chinese text-sm">
						<thead>
							<tr class="border-b border-slate-100 bg-slate-50">
								<th class="px-3 py-2 text-xs font-semibold text-slate-500">名次</th>
								<th class="px-3 py-2 text-xs font-semibold text-slate-500">正赛</th>
								<th class="px-3 py-2 text-xs font-semibold text-slate-500">安慰赛</th>
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
					<p class="font-chinese text-xs font-semibold text-amber-700 mb-1">特别奖项</p>
					<ul class="space-y-1 font-chinese text-xs text-amber-600">
						<li>• 最大年龄奖 $100</li>
						<li>• 最优混双奖 $100</li>
						<li>• 最优女双奖 $100</li>
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
				赛事赞助
			</h2>
			<p class="font-chinese text-slate-500">感谢以下赞助商的大力支持</p>
		</div>

		<!-- Title Sponsor -->
		<div class="mb-10 text-center">
			<p class="mb-4 font-chinese text-xs tracking-wider text-slate-400 uppercase">冠名赞助 / Title Sponsor</p>
			<div
				class="group inline-block rounded-2xl border-2 border-cta/20 bg-surface-warm px-12 py-8 transition-all duration-200 hover:border-cta/40 hover:shadow-md"
			>
				<div class="font-heading text-4xl tracking-wide text-primary-darker sm:text-5xl">
					{sponsors.title.name}
				</div>
				<div class="mt-1 font-body text-sm text-slate-400">{sponsors.title.nameEn}</div>
			</div>
		</div>

		<!-- Diamond Sponsors -->
		<div class="mb-8">
			<p class="mb-4 text-center font-chinese text-xs tracking-wider text-slate-400 uppercase">
				钻石赞助 / Diamond
			</p>
			<div class="flex flex-wrap items-center justify-center gap-6">
				{#each sponsors.diamond as name}
					<div class="rounded-xl border border-slate-100 bg-slate-50 px-8 py-4 font-chinese text-base font-medium text-slate-600 transition-all duration-200 hover:border-primary/20 hover:shadow-sm">
						{name}
					</div>
				{/each}
			</div>
		</div>

		<!-- Gold Sponsors -->
		<div>
			<p class="mb-4 text-center font-chinese text-xs tracking-wider text-slate-400 uppercase">
				黄金赞助 / Gold
			</p>
			<div class="flex flex-wrap items-center justify-center gap-4">
				{#each sponsors.gold as name}
					<div class="rounded-lg border border-slate-100 px-6 py-3 font-chinese text-sm text-slate-500 transition-all duration-200 hover:border-primary/20 hover:shadow-sm">
						{name}
					</div>
				{/each}
			</div>
		</div>

	</div>
</section>

<!-- ============================================ -->
<!-- BOTTOM CTA                                   -->
<!-- ============================================ -->
<section class="bg-primary-darker py-16 text-center text-white sm:py-20">
	<div class="mx-auto max-w-2xl px-4">
		<h2 class="mb-4 font-heading text-4xl tracking-wide sm:text-5xl">准备好了吗？</h2>
		<p class="mb-8 font-chinese text-lg text-white/70">
			名额有限，先到先得。立即报名，与你的搭档一起征战赛场！
		</p>
		<a
			href="/register"
			class="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-cta px-10 py-4 font-chinese text-lg font-bold text-white shadow-lg transition-all duration-200 hover:-translate-y-0.5 hover:bg-cta-hover hover:shadow-xl"
		>
			立即报名
			<ChevronRight class="h-5 w-5" />
		</a>
	</div>
</section>
