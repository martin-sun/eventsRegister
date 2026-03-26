<script lang="ts">
	import {
		Save,
		CalendarDays,
		MapPin,
		Users,
		Mail,
		Phone,
		MessageCircle,
		Clock,
		DollarSign,
		ToggleLeft,
		ToggleRight,
		Check,
		X,
		Loader2
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { supabase } from '$lib/supabase';
	import type { TournamentConfig } from '$lib/types';

	let { data } = $props();

	let config = $state<TournamentConfig>({ ...data.config });
	let saving = $state(false);
	let saveError = $state<string | null>(null);
	let saveSuccess = $state(false);

	// Convert ISO date to local datetime-local input value
	function toDatetimeLocal(iso: string): string {
		const d = new Date(iso);
		const offset = d.getTimezoneOffset();
		const local = new Date(d.getTime() - offset * 60000);
		return local.toISOString().slice(0, 16);
	}

	// Convert datetime-local value back to ISO with timezone
	function fromDatetimeLocal(val: string): string {
		const d = new Date(val);
		return d.toISOString();
	}

	let tournamentDateLocal = $state(toDatetimeLocal(data.config.tournament_date));
	let deadlineDateLocal = $state(toDatetimeLocal(data.config.registration_deadline));

	async function saveSettings() {
		saving = true;
		saveError = null;
		saveSuccess = false;

		const entries = [
			{ key: 'tournament_date', value: fromDatetimeLocal(tournamentDateLocal) },
			{ key: 'venue', value: { en: config.venue.en, zh: config.venue.zh } },
			{ key: 'registration_fee', value: config.registration_fee },
			{ key: 'min_age', value: config.min_age },
			{ key: 'registration_open', value: config.registration_open },
			{ key: 'registration_deadline', value: fromDatetimeLocal(deadlineDateLocal) },
			{ key: 'max_players', value: config.max_players },
			{ key: 'etransfer_email', value: config.etransfer_email },
			{ key: 'contact_phone', value: config.contact_phone },
			{ key: 'contact_wechat', value: config.contact_wechat },
			{ key: 'payment_deadline_hours', value: config.payment_deadline_hours }
		];

		const { error } = await supabase.rpc('admin_update_config', {
			p_entries: entries
		});

		if (error) {
			saveError = error.message;
		} else {
			saveSuccess = true;
			setTimeout(() => (saveSuccess = false), 3000);
		}

		saving = false;
	}
</script>

<svelte:head>
	<title>{m.admin_settings_title()}</title>
</svelte:head>

<div class="mx-auto max-w-3xl space-y-6">
	<!-- Header -->
	<div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
		<h1 class="font-heading text-3xl tracking-wide text-primary-darker">
			{m.admin_settings_title()}
		</h1>
		<button
			type="button"
			onclick={saveSettings}
			disabled={saving}
			class="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-primary px-6 py-2.5 font-chinese text-sm font-bold text-white shadow-sm transition-colors hover:bg-primary-dark disabled:cursor-not-allowed disabled:opacity-50"
		>
			{#if saving}
				<Loader2 class="h-4 w-4 animate-spin" />
				{m.admin_settings_saving()}
			{:else}
				<Save class="h-4 w-4" />
				{m.admin_settings_save()}
			{/if}
		</button>
	</div>

	<!-- Messages -->
	{#if saveError}
		<div
			class="flex items-center justify-between rounded-xl bg-danger/5 px-4 py-3 font-chinese text-sm text-danger"
		>
			<span>{saveError}</span>
			<button
				type="button"
				onclick={() => (saveError = null)}
				class="cursor-pointer text-danger/60 hover:text-danger"
			>
				<X class="h-4 w-4" />
			</button>
		</div>
	{/if}

	{#if saveSuccess}
		<div
			class="flex items-center gap-2 rounded-xl bg-emerald-50 px-4 py-3 font-chinese text-sm text-emerald-700"
		>
			<Check class="h-4 w-4" />
			{m.admin_settings_saved()}
		</div>
	{/if}

	<!-- Section: Event Info -->
	<div class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
		<h2 class="mb-5 flex items-center gap-2 font-chinese text-lg font-bold text-slate-900">
			<CalendarDays class="h-5 w-5 text-primary" />
			{m.admin_settings_section_event()}
		</h2>
		<div class="space-y-4">
			<!-- Tournament date -->
			<div>
				<label
					for="tournament_date"
					class="mb-1 block font-chinese text-xs font-medium text-slate-600"
				>
					{m.admin_settings_tournament_date()}
				</label>
				<input
					id="tournament_date"
					type="datetime-local"
					bind:value={tournamentDateLocal}
					class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
				/>
			</div>

			<!-- Venue -->
			<div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
				<div>
					<label
						for="venue_en"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						<MapPin class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
						{m.admin_settings_venue_en()}
					</label>
					<input
						id="venue_en"
						type="text"
						bind:value={config.venue.en}
						class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					/>
				</div>
				<div>
					<label
						for="venue_zh"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						<MapPin class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
						{m.admin_settings_venue_zh()}
					</label>
					<input
						id="venue_zh"
						type="text"
						bind:value={config.venue.zh}
						class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					/>
				</div>
			</div>
		</div>
	</div>

	<!-- Section: Registration -->
	<div class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
		<h2 class="mb-5 flex items-center gap-2 font-chinese text-lg font-bold text-slate-900">
			<Users class="h-5 w-5 text-primary" />
			{m.admin_settings_section_registration()}
		</h2>
		<div class="space-y-4">
			<!-- Registration open toggle -->
			<div class="flex items-center justify-between rounded-xl border border-slate-100 bg-slate-50 p-4">
				<div>
					<div class="font-chinese text-sm font-semibold text-slate-900">
						{m.admin_settings_registration_open()}
					</div>
					<div class="font-chinese text-xs text-slate-500">
						{m.admin_settings_registration_open_desc()}
					</div>
				</div>
				<button
					type="button"
					onclick={() => (config.registration_open = !config.registration_open)}
					class="cursor-pointer text-primary transition-colors"
				>
					{#if config.registration_open}
						<ToggleRight class="h-8 w-8" />
					{:else}
						<ToggleLeft class="h-8 w-8 text-slate-300" />
					{/if}
				</button>
			</div>

			<!-- Fee, min age, max players row -->
			<div class="grid grid-cols-3 gap-3">
				<div>
					<label
						for="reg_fee"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						<DollarSign class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
						{m.admin_settings_registration_fee()}
					</label>
					<input
						id="reg_fee"
						type="number"
						min="0"
						bind:value={config.registration_fee}
						class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					/>
				</div>
				<div>
					<label
						for="min_age"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						{m.admin_settings_min_age()}
					</label>
					<input
						id="min_age"
						type="number"
						min="0"
						bind:value={config.min_age}
						class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					/>
				</div>
				<div>
					<label
						for="max_players"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						{m.admin_settings_max_players()}
					</label>
					<input
						id="max_players"
						type="number"
						min="1"
						bind:value={config.max_players}
						class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					/>
				</div>
			</div>

			<!-- Registration deadline -->
			<div>
				<label
					for="reg_deadline"
					class="mb-1 block font-chinese text-xs font-medium text-slate-600"
				>
					<Clock class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
					{m.admin_settings_registration_deadline()}
				</label>
				<input
					id="reg_deadline"
					type="datetime-local"
					bind:value={deadlineDateLocal}
					class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
				/>
			</div>
		</div>
	</div>

	<!-- Section: Payment & Contact -->
	<div class="rounded-2xl border border-slate-100 bg-white p-6 shadow-sm">
		<h2 class="mb-5 flex items-center gap-2 font-chinese text-lg font-bold text-slate-900">
			<Mail class="h-5 w-5 text-primary" />
			{m.admin_settings_section_payment()}
		</h2>
		<div class="space-y-4">
			<!-- E-Transfer email -->
			<div>
				<label
					for="etransfer"
					class="mb-1 block font-chinese text-xs font-medium text-slate-600"
				>
					<DollarSign class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
					{m.admin_settings_etransfer_email()}
				</label>
				<input
					id="etransfer"
					type="email"
					bind:value={config.etransfer_email}
					class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
				/>
			</div>

			<!-- Contact phone + wechat -->
			<div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
				<div>
					<label
						for="phone"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						<Phone class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
						{m.admin_settings_contact_phone()}
					</label>
					<input
						id="phone"
						type="text"
						bind:value={config.contact_phone}
						class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					/>
				</div>
				<div>
					<label
						for="wechat"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						<MessageCircle class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
						{m.admin_settings_contact_wechat()}
					</label>
					<input
						id="wechat"
						type="text"
						bind:value={config.contact_wechat}
						class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					/>
				</div>
			</div>

			<!-- Payment deadline hours -->
			<div class="w-48">
				<label
					for="pay_deadline"
					class="mb-1 block font-chinese text-xs font-medium text-slate-600"
				>
					<Clock class="mr-1 inline h-3.5 w-3.5 text-slate-400" />
					{m.admin_settings_payment_deadline_hours()}
				</label>
				<input
					id="pay_deadline"
					type="number"
					min="1"
					bind:value={config.payment_deadline_hours}
					class="w-full rounded-xl border border-slate-200 px-4 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
				/>
			</div>
		</div>
	</div>

	<!-- Bottom save button -->
	<div class="flex justify-end pb-8">
		<button
			type="button"
			onclick={saveSettings}
			disabled={saving}
			class="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-primary px-8 py-3 font-chinese text-sm font-bold text-white shadow-sm transition-colors hover:bg-primary-dark disabled:cursor-not-allowed disabled:opacity-50"
		>
			{#if saving}
				<Loader2 class="h-4 w-4 animate-spin" />
				{m.admin_settings_saving()}
			{:else}
				<Save class="h-4 w-4" />
				{m.admin_settings_save()}
			{/if}
		</button>
	</div>
</div>
