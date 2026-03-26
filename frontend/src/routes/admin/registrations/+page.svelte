<script lang="ts">
	import {
		Search,
		Download,
		DollarSign,
		CheckCircle,
		XCircle,
		Clock,
		ChevronDown,
		ChevronUp,
		X,
		Mail,
		Phone,
		MessageCircle,
		Copy,
		Check
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import { supabase } from '$lib/supabase';
	import type { AdminTeam } from '$lib/types';
	import { invalidateAll } from '$app/navigation';

	let { data } = $props();

	let teams = $state<AdminTeam[]>(data.teams);
	let searchQuery = $state('');
	let paymentFilter = $state<'all' | 'unpaid' | 'paid'>('all');
	let expandedTeamId = $state<string | null>(null);
	let locale = $derived(getLocale());
	let actionError = $state<string | null>(null);

	// Payment modal state
	let paymentModal = $state<{ open: boolean; team: AdminTeam | null; notes: string; loading: boolean }>({
		open: false,
		team: null,
		notes: '',
		loading: false
	});

	// Copied state
	let copiedField = $state<string | null>(null);

	// Filtered teams
	let filteredTeams = $derived.by(() => {
		let result = teams;

		if (paymentFilter !== 'all') {
			result = result.filter((t) => t.payment_status === paymentFilter);
		}

		if (searchQuery.trim()) {
			const q = searchQuery.toLowerCase();
			result = result.filter(
				(t) =>
					formatPaymentRef(t.team_id).toLowerCase().includes(q) ||
					t.player1_name_en.toLowerCase().includes(q) ||
					t.player2_name_en.toLowerCase().includes(q) ||
					(t.player1_name_zh && t.player1_name_zh.toLowerCase().includes(q)) ||
					(t.player2_name_zh && t.player2_name_zh.toLowerCase().includes(q))
			);
		}

		return result;
	});

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

	function toggleExpand(teamId: string) {
		expandedTeamId = expandedTeamId === teamId ? null : teamId;
	}

	// --- Actions ---
	function openPaymentModal(team: AdminTeam) {
		paymentModal = { open: true, team, notes: '', loading: false };
	}

	function closePaymentModal() {
		paymentModal = { open: false, team: null, notes: '', loading: false };
	}

	async function confirmPayment() {
		if (!paymentModal.team) return;
		paymentModal.loading = true;
		actionError = null;

		const { error } = await supabase.rpc('admin_mark_payment', {
			p_team_id: paymentModal.team.team_id,
			p_payment_notes: paymentModal.notes || null
		});

		if (!error) {
			const idx = teams.findIndex((t) => t.team_id === paymentModal.team!.team_id);
			if (idx !== -1) {
				teams[idx] = {
					...teams[idx],
					payment_status: 'paid',
					paid_at: new Date().toISOString(),
					payment_notes: paymentModal.notes || null
				};
			}
			closePaymentModal();
		} else {
			paymentModal.loading = false;
			actionError = error.message;
		}
	}

	async function updateTeamStatus(teamId: string, newStatus: string) {
		actionError = null;

		const { error } = await supabase.rpc('admin_update_team_status', {
			p_team_id: teamId,
			p_status: newStatus
		});

		if (!error) {
			const idx = teams.findIndex((t) => t.team_id === teamId);
			if (idx !== -1) {
				teams[idx] = { ...teams[idx], status: newStatus as AdminTeam['status'] };
			}
		} else {
			actionError = error.message;
		}
	}

	async function copyText(text: string, field: string) {
		await navigator.clipboard.writeText(text);
		copiedField = field;
		setTimeout(() => (copiedField = null), 2000);
	}

	function exportCsv() {
		const headers = [
			'Ref', 'Player 1', 'P1 Gender', 'P1 Age', 'P1 Email', 'P1 Phone', 'P1 WeChat',
			'Player 2', 'P2 Gender', 'P2 Age', 'P2 Email', 'P2 Phone', 'P2 WeChat',
			'Category', 'Type', 'Combined Age', 'Status', 'Payment', 'Paid At', 'Registered'
		];
		const rows = filteredTeams.map((t) => [
			formatPaymentRef(t.team_id),
			t.player1_name_en,
			t.player1_gender,
			t.player1_age,
			t.player1_email,
			t.player1_phone || '',
			t.player1_wechat || '',
			t.player2_name_en,
			t.player2_gender,
			t.player2_age,
			t.player2_email,
			t.player2_phone || '',
			t.player2_wechat || '',
			t.category_en,
			t.gender_type,
			t.combined_age,
			t.status,
			t.payment_status,
			t.paid_at || '',
			t.created_at
		]);

		const csv = [headers, ...rows].map((r) => r.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n');
		const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `registrations_${new Date().toISOString().slice(0, 10)}.csv`;
		a.click();
		URL.revokeObjectURL(url);
	}
</script>

<svelte:head>
	<title>{m.admin_reg_title()}</title>
</svelte:head>

<div class="space-y-6">
	<!-- Header -->
	{#if actionError}
		<div class="rounded-xl bg-danger/5 px-4 py-3 font-chinese text-sm text-danger flex items-center justify-between">
			<span>{actionError}</span>
			<button type="button" onclick={() => actionError = null} class="cursor-pointer text-danger/60 hover:text-danger">
				<X class="h-4 w-4" />
			</button>
		</div>
	{/if}

	<div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
		<h1 class="font-heading text-3xl tracking-wide text-primary-darker">{m.admin_reg_title()}</h1>
		<button
			type="button"
			onclick={exportCsv}
			class="inline-flex cursor-pointer items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2.5 font-chinese text-sm font-medium text-slate-700 shadow-sm transition-colors hover:bg-slate-50"
		>
			<Download class="h-4 w-4" />
			{m.admin_reg_export_csv()}
		</button>
	</div>

	<!-- Filters -->
	<div class="flex flex-col gap-3 sm:flex-row">
		<!-- Payment filter tabs -->
		<div class="flex rounded-xl border border-slate-200 bg-white p-1">
			{#each [
				{ key: 'all', label: m.admin_reg_filter_all() },
				{ key: 'unpaid', label: m.admin_reg_filter_unpaid() },
				{ key: 'paid', label: m.admin_reg_filter_paid() }
			] as tab}
				<button
					type="button"
					onclick={() => (paymentFilter = tab.key as typeof paymentFilter)}
					class="cursor-pointer rounded-lg px-4 py-2 font-chinese text-sm font-medium transition-all duration-200
					{paymentFilter === tab.key ? 'bg-primary text-white shadow-sm' : 'text-slate-500 hover:text-slate-700'}"
				>
					{tab.label}
				</button>
			{/each}
		</div>

		<!-- Search -->
		<div class="relative flex-1">
			<Search class="pointer-events-none absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
			<input
				type="text"
				bind:value={searchQuery}
				placeholder={m.admin_reg_search()}
				class="w-full rounded-xl border border-slate-200 bg-white py-2.5 pl-10 pr-4 font-chinese text-sm text-slate-900 placeholder:text-slate-400 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
			/>
		</div>
	</div>

	<!-- Count -->
	<div class="font-chinese text-sm text-slate-500">
		{filteredTeams.length} {m.admin_dash_teams_unit()}
	</div>

	<!-- Teams List -->
	{#if filteredTeams.length === 0}
		<div class="rounded-2xl border border-slate-100 bg-white py-16 text-center shadow-sm">
			<p class="font-chinese text-slate-400">{m.admin_reg_empty()}</p>
		</div>
	{:else}
		<div class="space-y-3">
			{#each filteredTeams as team (team.team_id)}
				{@const isExpanded = expandedTeamId === team.team_id}
				<div class="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm transition-shadow hover:shadow-md">
					<!-- Main row -->
					<div class="flex items-center gap-3 px-4 py-4 sm:px-6">
						<!-- Ref -->
						<div class="w-20 shrink-0">
							<span class="font-mono text-xs font-bold text-primary-darker">{formatPaymentRef(team.team_id)}</span>
						</div>

						<!-- Players -->
						<div class="min-w-0 flex-1">
							<div class="truncate font-chinese text-sm font-semibold text-slate-900">
								{team.player1_name_en} & {team.player2_name_en}
							</div>
							<div class="font-chinese text-xs text-slate-400">
								{locale === 'zh' ? team.category_zh : team.category_en} · {team.gender_type === 'mens' ? m.reg_mens() : team.gender_type === 'womens' ? m.reg_womens() : m.reg_mixed()} · {team.combined_age}{m.reg_age_suffix()}
							</div>
							<!-- Contact info -->
							<div class="mt-1 hidden space-y-0.5 sm:block">
								<div class="flex items-center gap-3 text-xs text-slate-500">
									<span class="flex items-center gap-1"><Mail class="h-3 w-3 text-slate-300" />{team.player1_email}</span>
									{#if team.player1_phone}<span class="flex items-center gap-1"><Phone class="h-3 w-3 text-slate-300" />{team.player1_phone}</span>{/if}
									{#if team.player1_wechat}<span class="flex items-center gap-1"><MessageCircle class="h-3 w-3 text-slate-300" />{team.player1_wechat}</span>{/if}
								</div>
								<div class="flex items-center gap-3 text-xs text-slate-500">
									<span class="flex items-center gap-1"><Mail class="h-3 w-3 text-slate-300" />{team.player2_email}</span>
									{#if team.player2_phone}<span class="flex items-center gap-1"><Phone class="h-3 w-3 text-slate-300" />{team.player2_phone}</span>{/if}
									{#if team.player2_wechat}<span class="flex items-center gap-1"><MessageCircle class="h-3 w-3 text-slate-300" />{team.player2_wechat}</span>{/if}
								</div>
							</div>
						</div>

						<!-- Status badge -->
						<span class="hidden shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold sm:inline-flex
							{team.status === 'confirmed' ? 'bg-primary/10 text-primary' : team.status === 'pending' ? 'bg-amber-50 text-amber-700' : team.status === 'waitlist' ? 'bg-slate-100 text-slate-600' : 'bg-danger/10 text-danger'}">
							{team.status === 'confirmed' ? m.admin_status_confirmed() : team.status === 'pending' ? m.admin_status_pending() : team.status === 'waitlist' ? m.admin_status_waitlist() : m.admin_status_cancelled()}
						</span>

						<!-- Payment badge -->
						<span class="shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold
							{team.payment_status === 'paid' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'}">
							{team.payment_status === 'paid' ? m.pay_status_paid() : m.pay_status_unpaid()}
						</span>

						<!-- Actions -->
						<div class="flex shrink-0 items-center gap-1">
							{#if team.payment_status === 'unpaid' && team.status !== 'cancelled'}
								<button
									type="button"
									onclick={() => openPaymentModal(team)}
									class="cursor-pointer rounded-lg bg-emerald-50 px-3 py-1.5 font-chinese text-xs font-semibold text-emerald-700 transition-colors hover:bg-emerald-100"
								>
									<DollarSign class="inline h-3.5 w-3.5" />
									{m.admin_reg_mark_paid()}
								</button>
							{/if}
							<button
								type="button"
								onclick={() => toggleExpand(team.team_id)}
								class="cursor-pointer rounded-lg p-2 text-slate-400 transition-colors hover:bg-slate-50 hover:text-slate-600"
							>
								{#if isExpanded}
									<ChevronUp class="h-4 w-4" />
								{:else}
									<ChevronDown class="h-4 w-4" />
								{/if}
							</button>
						</div>
					</div>

					<!-- Expanded details -->
					{#if isExpanded}
						<div class="border-t border-slate-100 bg-slate-50/50 px-4 py-5 sm:px-6">
							<div class="grid gap-6 sm:grid-cols-2">
								<!-- Player 1 -->
								<div class="space-y-2">
									<div class="font-chinese text-xs font-bold text-slate-500 uppercase">{m.reg_player1_title()}</div>
									<div class="font-chinese text-sm font-semibold text-slate-900">
										{team.player1_name_en}
										{#if team.player1_name_zh}
											<span class="text-slate-400">({team.player1_name_zh})</span>
										{/if}
									</div>
									<div class="space-y-1 text-sm">
										<div class="flex items-center gap-2 text-slate-600">
											<Mail class="h-3.5 w-3.5 text-slate-400" />
											{team.player1_email}
											<button type="button" onclick={() => copyText(team.player1_email, 'p1e')} class="cursor-pointer text-slate-300 hover:text-slate-500">
												{#if copiedField === 'p1e'}<Check class="h-3.5 w-3.5 text-primary" />{:else}<Copy class="h-3.5 w-3.5" />{/if}
											</button>
										</div>
										{#if team.player1_phone}
											<div class="flex items-center gap-2 text-slate-600">
												<Phone class="h-3.5 w-3.5 text-slate-400" />
												{team.player1_phone}
											</div>
										{/if}
										{#if team.player1_wechat}
											<div class="flex items-center gap-2 text-slate-600">
												<MessageCircle class="h-3.5 w-3.5 text-slate-400" />
												{team.player1_wechat}
											</div>
										{/if}
										<div class="text-slate-500">
											{team.player1_gender === 'male' ? m.reg_gender_male() : m.reg_gender_female()} · {team.player1_age}{m.reg_age_suffix()}
										</div>
									</div>
								</div>

								<!-- Player 2 -->
								<div class="space-y-2">
									<div class="font-chinese text-xs font-bold text-slate-500 uppercase">{m.reg_player2_title()}</div>
									<div class="font-chinese text-sm font-semibold text-slate-900">
										{team.player2_name_en}
										{#if team.player2_name_zh}
											<span class="text-slate-400">({team.player2_name_zh})</span>
										{/if}
									</div>
									<div class="space-y-1 text-sm">
										<div class="flex items-center gap-2 text-slate-600">
											<Mail class="h-3.5 w-3.5 text-slate-400" />
											{team.player2_email}
											<button type="button" onclick={() => copyText(team.player2_email, 'p2e')} class="cursor-pointer text-slate-300 hover:text-slate-500">
												{#if copiedField === 'p2e'}<Check class="h-3.5 w-3.5 text-primary" />{:else}<Copy class="h-3.5 w-3.5" />{/if}
											</button>
										</div>
										{#if team.player2_phone}
											<div class="flex items-center gap-2 text-slate-600">
												<Phone class="h-3.5 w-3.5 text-slate-400" />
												{team.player2_phone}
											</div>
										{/if}
										{#if team.player2_wechat}
											<div class="flex items-center gap-2 text-slate-600">
												<MessageCircle class="h-3.5 w-3.5 text-slate-400" />
												{team.player2_wechat}
											</div>
										{/if}
										<div class="text-slate-500">
											{team.player2_gender === 'male' ? m.reg_gender_male() : m.reg_gender_female()} · {team.player2_age}{m.reg_age_suffix()}
										</div>
									</div>
								</div>
							</div>

							<!-- Payment info -->
							{#if team.paid_at}
								<div class="mt-4 rounded-xl bg-emerald-50 p-3 font-chinese text-xs text-emerald-700">
									{m.pay_status_paid()} · {formatDate(team.paid_at)}
									{#if team.payment_notes}
										<span class="text-emerald-600"> — {team.payment_notes}</span>
									{/if}
								</div>
							{/if}

							<!-- Status actions -->
							{#if team.status !== 'cancelled'}
								<div class="mt-4 flex flex-wrap gap-2 border-t border-slate-100 pt-4">
									{#if team.status === 'pending'}
										<button
											type="button"
											onclick={() => updateTeamStatus(team.team_id, 'confirmed')}
											class="inline-flex cursor-pointer items-center gap-1 rounded-lg bg-primary/10 px-3 py-1.5 font-chinese text-xs font-semibold text-primary transition-colors hover:bg-primary/20"
										>
											<CheckCircle class="h-3.5 w-3.5" />
											{m.admin_reg_confirm()}
										</button>
									{/if}
									{#if team.status === 'waitlist'}
										<button
											type="button"
											onclick={() => updateTeamStatus(team.team_id, 'confirmed')}
											class="inline-flex cursor-pointer items-center gap-1 rounded-lg bg-primary/10 px-3 py-1.5 font-chinese text-xs font-semibold text-primary transition-colors hover:bg-primary/20"
										>
											<CheckCircle class="h-3.5 w-3.5" />
											{m.admin_reg_confirm()}
										</button>
									{/if}
									<button
										type="button"
										onclick={() => updateTeamStatus(team.team_id, 'cancelled')}
										class="inline-flex cursor-pointer items-center gap-1 rounded-lg bg-danger/10 px-3 py-1.5 font-chinese text-xs font-semibold text-danger transition-colors hover:bg-danger/20"
									>
										<XCircle class="h-3.5 w-3.5" />
										{m.admin_reg_cancel()}
									</button>
								</div>
							{/if}

							<!-- Meta -->
							<div class="mt-3 font-chinese text-xs text-slate-400">
								{m.admin_reg_ref()}: {team.team_id} · {formatDate(team.created_at)}
							</div>
						</div>
					{/if}
				</div>
			{/each}
		</div>
	{/if}
</div>

<!-- Payment Confirmation Modal -->
{#if paymentModal.open && paymentModal.team}
	{@const team = paymentModal.team}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4">
		<!-- Backdrop -->
		<button
			type="button"
			class="fixed inset-0 bg-black/40 backdrop-blur-sm"
			onclick={closePaymentModal}
			aria-label="Close"
		></button>

		<!-- Modal -->
		<div class="relative w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl">
			<button
				type="button"
				onclick={closePaymentModal}
				class="absolute right-4 top-4 cursor-pointer p-1 text-slate-400 hover:text-slate-600"
			>
				<X class="h-5 w-5" />
			</button>

			<div class="mb-6">
				<div class="mb-2 flex items-center gap-2">
					<DollarSign class="h-5 w-5 text-emerald-600" />
					<h3 class="font-chinese text-lg font-bold text-slate-900">{m.admin_pay_modal_title()}</h3>
				</div>
			</div>

			<div class="mb-6 space-y-3 rounded-xl bg-slate-50 p-4">
				<div class="flex justify-between font-chinese text-sm">
					<span class="text-slate-500">{m.admin_pay_modal_team()}</span>
					<span class="font-semibold text-slate-900">{team.player1_name_en} & {team.player2_name_en}</span>
				</div>
				<div class="flex justify-between font-chinese text-sm">
					<span class="text-slate-500">{m.admin_pay_modal_ref()}</span>
					<span class="font-mono font-bold text-primary-darker">{formatPaymentRef(team.team_id)}</span>
				</div>
				<div class="flex justify-between font-chinese text-sm">
					<span class="text-slate-500">{m.admin_pay_modal_amount()}</span>
					<span class="font-bold text-emerald-700">${data.config.registration_fee * 2}.00 CAD</span>
				</div>
			</div>

			<div class="mb-6">
				<label for="pay-notes" class="mb-1.5 block font-chinese text-sm font-medium text-slate-700">
					{m.admin_pay_modal_notes()}
				</label>
				<textarea
					id="pay-notes"
					bind:value={paymentModal.notes}
					placeholder={m.admin_pay_modal_notes_placeholder()}
					rows="2"
					class="w-full rounded-xl border border-slate-200 px-4 py-3 font-chinese text-sm text-slate-900 placeholder:text-slate-400 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
				></textarea>
			</div>

			<div class="flex gap-3">
				<button
					type="button"
					onclick={closePaymentModal}
					class="flex-1 cursor-pointer rounded-xl border border-slate-200 py-3 font-chinese text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50"
				>
					{m.admin_pay_modal_cancel()}
				</button>
				<button
					type="button"
					onclick={confirmPayment}
					disabled={paymentModal.loading}
					class="flex-1 cursor-pointer rounded-xl bg-emerald-600 py-3 font-chinese text-sm font-bold text-white transition-colors hover:bg-emerald-700 disabled:opacity-50"
				>
					{m.admin_pay_modal_confirm()}
				</button>
			</div>
		</div>
	</div>
{/if}
