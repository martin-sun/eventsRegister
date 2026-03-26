<script lang="ts">
	import {
		Users,
		CheckCircle,
		Clock,
		ListOrdered,
		DollarSign,
		AlertCircle,
		TrendingUp,
		ArrowRight
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import { supabase } from '$lib/supabase';
	import type { DashboardStats, AdminTeam, CategoryStat } from '$lib/types';
	import { onMount } from 'svelte';

	let { data } = $props();

	let stats = $state<DashboardStats | null>(null);
	let loading = $state(true);

	onMount(async () => {
		const { data: result } = await supabase.rpc('admin_dashboard_stats');
		if (result) {
			stats = result as DashboardStats;
		}
		loading = false;
	});

	let recentTeams = $derived(data.recentTeams as AdminTeam[]);
	let categories = $derived(data.categories as CategoryStat[]);
	let locale = $derived(getLocale());

	function formatPaymentRef(teamId: string): string {
		return teamId.replace(/-/g, '').substring(0, 8).toUpperCase();
	}

	function formatDate(dateStr: string): string {
		return new Date(dateStr).toLocaleDateString(locale === 'zh' ? 'zh-CN' : 'en-CA', {
			month: 'short',
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}
</script>

<svelte:head>
	<title>{m.admin_dash_title()}</title>
</svelte:head>

<div class="space-y-6">
	<h1 class="font-heading text-3xl tracking-wide text-primary-darker">{m.admin_dash_title()}</h1>

	<!-- Stats Grid -->
	{#if stats}
		<div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
			<!-- Total -->
			<div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
				<div class="mb-2 flex items-center gap-2 text-slate-500">
					<Users class="h-4 w-4" />
					<span class="font-chinese text-xs font-medium">{m.admin_dash_total_teams()}</span>
				</div>
				<div class="font-heading text-3xl text-slate-900">{stats.total_teams}</div>
			</div>
			<!-- Confirmed -->
			<div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
				<div class="mb-2 flex items-center gap-2 text-primary">
					<CheckCircle class="h-4 w-4" />
					<span class="font-chinese text-xs font-medium">{m.admin_dash_confirmed()}</span>
				</div>
				<div class="font-heading text-3xl text-primary">{stats.confirmed_teams}</div>
			</div>
			<!-- Paid -->
			<div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
				<div class="mb-2 flex items-center gap-2 text-emerald-600">
					<DollarSign class="h-4 w-4" />
					<span class="font-chinese text-xs font-medium">{m.admin_dash_paid()}</span>
				</div>
				<div class="font-heading text-3xl text-emerald-600">{stats.paid_teams}</div>
			</div>
			<!-- Unpaid -->
			<div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
				<div class="mb-2 flex items-center gap-2 text-amber-600">
					<AlertCircle class="h-4 w-4" />
					<span class="font-chinese text-xs font-medium">{m.admin_dash_unpaid()}</span>
				</div>
				<div class="font-heading text-3xl text-amber-600">{stats.unpaid_teams}</div>
			</div>
		</div>

		<!-- Revenue -->
		<div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
			<div class="rounded-2xl border border-emerald-100 bg-emerald-50/50 p-5">
				<div class="mb-1 flex items-center gap-2 text-emerald-700">
					<TrendingUp class="h-4 w-4" />
					<span class="font-chinese text-sm font-medium">{m.admin_dash_revenue()}</span>
				</div>
				<div class="font-heading text-4xl text-emerald-700">${stats.total_revenue}</div>
			</div>
			<div class="rounded-2xl border border-slate-100 bg-white p-5">
				<div class="mb-1 flex items-center gap-2 text-slate-500">
					<DollarSign class="h-4 w-4" />
					<span class="font-chinese text-sm font-medium">{m.admin_dash_expected()}</span>
				</div>
				<div class="font-heading text-4xl text-slate-700">${stats.expected_revenue}</div>
			</div>
		</div>
	{:else if loading}
		<div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
			{#each Array(4) as _}
				<div class="h-24 animate-pulse rounded-2xl bg-slate-100"></div>
			{/each}
		</div>
	{/if}

	<!-- Category Stats -->
	{#if categories.length > 0}
		<div class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
			<h2 class="mb-4 font-chinese text-lg font-bold text-slate-900">{m.admin_dash_category_stats()}</h2>
			<div class="grid gap-4 sm:grid-cols-2">
				{#each categories as cat}
					<div class="rounded-xl border border-slate-100 p-4">
						<div class="mb-2 font-chinese text-sm font-semibold text-slate-700">
							{locale === 'zh' ? cat.name_zh : cat.name_en}
						</div>
						<div class="mb-2 flex items-baseline gap-2">
							<span class="font-heading text-2xl text-primary-darker">{cat.registered_teams}</span>
							<span class="font-chinese text-sm text-slate-400">/ {cat.max_teams} {m.admin_dash_teams_unit()}</span>
						</div>
						<div class="h-2 overflow-hidden rounded-full bg-slate-100">
							<div
								class="h-full rounded-full bg-primary transition-all duration-500"
								style="width: {Math.min((cat.registered_teams / cat.max_teams) * 100, 100)}%"
							></div>
						</div>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	<!-- Recent Registrations -->
	<div class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
		<div class="mb-4 flex items-center justify-between">
			<h2 class="font-chinese text-lg font-bold text-slate-900">{m.admin_dash_recent()}</h2>
			<a
				href="/admin/registrations"
				class="flex items-center gap-1 font-chinese text-sm text-primary transition-colors hover:text-primary-dark"
			>
				{m.admin_nav_registrations()}
				<ArrowRight class="h-4 w-4" />
			</a>
		</div>

		{#if recentTeams.length === 0}
			<p class="py-8 text-center font-chinese text-sm text-slate-400">{m.admin_reg_empty()}</p>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left">
					<thead>
						<tr class="border-b border-slate-100 font-chinese text-xs font-medium text-slate-500">
							<th class="pb-3 pr-4">{m.admin_reg_ref()}</th>
							<th class="pb-3 pr-4">{m.admin_reg_players()}</th>
							<th class="pb-3 pr-4">{m.admin_reg_type()}</th>
							<th class="pb-3 pr-4">{m.admin_reg_status()}</th>
							<th class="pb-3">{m.admin_reg_payment()}</th>
						</tr>
					</thead>
					<tbody>
						{#each recentTeams.slice(0, 5) as team}
							<tr class="border-b border-slate-50">
								<td class="py-3 pr-4 font-mono text-xs font-bold text-primary-darker">{formatPaymentRef(team.team_id)}</td>
								<td class="py-3 pr-4 font-chinese text-sm text-slate-700">
									{team.player1_name_en} / {team.player2_name_en}
								</td>
								<td class="py-3 pr-4">
									<span class="inline-flex rounded-full px-2 py-0.5 text-xs font-semibold
										{team.gender_type === 'mens' ? 'bg-blue-50 text-blue-700' : team.gender_type === 'womens' ? 'bg-pink-50 text-pink-700' : 'bg-purple-50 text-purple-700'}">
										{team.gender_type === 'mens' ? m.reg_mens() : team.gender_type === 'womens' ? m.reg_womens() : m.reg_mixed()}
									</span>
								</td>
								<td class="py-3 pr-4">
									<span class="inline-flex rounded-full px-2 py-0.5 text-xs font-semibold
										{team.status === 'confirmed' ? 'bg-primary/10 text-primary' : team.status === 'pending' ? 'bg-amber-50 text-amber-700' : team.status === 'waitlist' ? 'bg-slate-100 text-slate-600' : 'bg-danger/10 text-danger'}">
										{team.status === 'confirmed' ? m.admin_status_confirmed() : team.status === 'pending' ? m.admin_status_pending() : team.status === 'waitlist' ? m.admin_status_waitlist() : m.admin_status_cancelled()}
									</span>
								</td>
								<td class="py-3">
									<span class="inline-flex rounded-full px-2 py-0.5 text-xs font-semibold
										{team.payment_status === 'paid' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}">
										{team.payment_status === 'paid' ? m.pay_status_paid() : m.pay_status_unpaid()}
									</span>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</div>
</div>
