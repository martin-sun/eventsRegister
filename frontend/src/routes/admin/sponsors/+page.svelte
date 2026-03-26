<script lang="ts">
	import {
		Plus,
		Pencil,
		Trash2,
		X,
		Check,
		Eye,
		EyeOff,
		GripVertical,
		ExternalLink,
		Loader2
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import { supabase } from '$lib/supabase';

	interface SponsorRow {
		id: string;
		name_zh: string;
		name_en: string;
		level: string;
		logo_url: string | null;
		website: string | null;
		contact_name: string | null;
		contact_phone: string | null;
		contact_email: string | null;
		amount: number;
		is_confirmed: boolean;
		description_zh: string | null;
		description_en: string | null;
		sort_order: number;
		created_at: string;
	}

	const LEVELS = ['title', 'diamond', 'platinum', 'gold', 'friend', 'media'] as const;

	const levelLabels: Record<string, () => string> = {
		title: () => m.admin_sponsor_level_title(),
		diamond: () => m.admin_sponsor_level_diamond(),
		platinum: () => m.admin_sponsor_level_platinum(),
		gold: () => m.admin_sponsor_level_gold(),
		friend: () => m.admin_sponsor_level_friend(),
		media: () => m.admin_sponsor_level_media()
	};

	const levelColors: Record<string, string> = {
		title: 'bg-amber-100 text-amber-800',
		diamond: 'bg-sky-100 text-sky-800',
		platinum: 'bg-slate-200 text-slate-800',
		gold: 'bg-yellow-100 text-yellow-800',
		friend: 'bg-emerald-100 text-emerald-800',
		media: 'bg-purple-100 text-purple-800'
	};

	let { data } = $props();

	let sponsors = $state<SponsorRow[]>(data.sponsors);
	let statusFilter = $state<'all' | 'confirmed' | 'unconfirmed'>('all');
	let locale = $derived(getLocale());
	let actionError = $state<string | null>(null);
	let saving = $state(false);

	// Modal state
	let modalOpen = $state(false);
	let editingSponsor = $state<SponsorRow | null>(null);

	// Form state
	let form = $state({
		name_zh: '',
		name_en: '',
		level: 'friend' as string,
		logo_url: '',
		website: '',
		contact_name: '',
		contact_phone: '',
		contact_email: '',
		is_confirmed: false,
		description_zh: '',
		description_en: '',
		sort_order: 0
	});

	// Filtered sponsors
	let filteredSponsors = $derived.by(() => {
		if (statusFilter === 'confirmed') return sponsors.filter((s) => s.is_confirmed);
		if (statusFilter === 'unconfirmed') return sponsors.filter((s) => !s.is_confirmed);
		return sponsors;
	});

	function sponsorName(s: SponsorRow): string {
		return locale === 'zh' ? s.name_zh : s.name_en;
	}

	function openAddModal() {
		editingSponsor = null;
		form = {
			name_zh: '',
			name_en: '',
			level: 'friend',
			logo_url: '',
			website: '',
			contact_name: '',
			contact_phone: '',
			contact_email: '',
			is_confirmed: false,
			description_zh: '',
			description_en: '',
			sort_order: sponsors.length > 0 ? Math.max(...sponsors.map((s) => s.sort_order)) + 10 : 10
		};
		modalOpen = true;
	}

	function openEditModal(sponsor: SponsorRow) {
		editingSponsor = sponsor;
		form = {
			name_zh: sponsor.name_zh,
			name_en: sponsor.name_en,
			level: sponsor.level,
			logo_url: sponsor.logo_url ?? '',
			website: sponsor.website ?? '',
			contact_name: sponsor.contact_name ?? '',
			contact_phone: sponsor.contact_phone ?? '',
			contact_email: sponsor.contact_email ?? '',
			is_confirmed: sponsor.is_confirmed,
			description_zh: sponsor.description_zh ?? '',
			description_en: sponsor.description_en ?? '',
			sort_order: sponsor.sort_order
		};
		modalOpen = true;
	}

	function closeModal() {
		modalOpen = false;
		editingSponsor = null;
	}

	async function saveSponsor() {
		if (!form.name_zh.trim() || !form.name_en.trim()) return;
		saving = true;
		actionError = null;

		const params: Record<string, unknown> = {
			p_name_zh: form.name_zh.trim(),
			p_name_en: form.name_en.trim(),
			p_level: form.level,
			p_logo_url: form.logo_url.trim() || null,
			p_website: form.website.trim() || null,
			p_contact_name: form.contact_name.trim() || null,
			p_contact_phone: form.contact_phone.trim() || null,
			p_contact_email: form.contact_email.trim() || null,
			p_is_confirmed: form.is_confirmed,
			p_description_zh: form.description_zh.trim() || null,
			p_description_en: form.description_en.trim() || null,
			p_sort_order: form.sort_order
		};

		if (editingSponsor) {
			params.p_id = editingSponsor.id;
		}

		const { data: newId, error } = await supabase.rpc('admin_upsert_sponsor', params);

		if (error) {
			actionError = error.message;
			saving = false;
			return;
		}

		// Refresh list
		const { data: refreshed } = await supabase
			.from('sponsors')
			.select('*')
			.order('sort_order');

		if (refreshed) {
			sponsors = refreshed as SponsorRow[];
		}

		saving = false;
		closeModal();
	}

	async function deleteSponsor(sponsor: SponsorRow) {
		const name = sponsorName(sponsor);
		if (!confirm(m.admin_sponsor_delete_confirm({ name }))) return;

		actionError = null;
		const { error } = await supabase.rpc('admin_delete_sponsor', { p_id: sponsor.id });

		if (error) {
			actionError = error.message;
			return;
		}

		sponsors = sponsors.filter((s) => s.id !== sponsor.id);
	}

	async function toggleConfirmed(sponsor: SponsorRow) {
		actionError = null;
		const { data: newStatus, error } = await supabase.rpc('admin_toggle_sponsor_confirmed', {
			p_id: sponsor.id
		});

		if (error) {
			actionError = error.message;
			return;
		}

		const idx = sponsors.findIndex((s) => s.id === sponsor.id);
		if (idx !== -1) {
			sponsors[idx] = { ...sponsors[idx], is_confirmed: newStatus as boolean };
		}
	}
</script>

<svelte:head>
	<title>{m.admin_sponsor_title()}</title>
</svelte:head>

<div class="space-y-6">
	<!-- Header -->
	{#if actionError}
		<div
			class="flex items-center justify-between rounded-xl bg-danger/5 px-4 py-3 font-chinese text-sm text-danger"
		>
			<span>{actionError}</span>
			<button
				type="button"
				onclick={() => (actionError = null)}
				class="cursor-pointer text-danger/60 hover:text-danger"
			>
				<X class="h-4 w-4" />
			</button>
		</div>
	{/if}

	<div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
		<h1 class="font-heading text-3xl tracking-wide text-primary-darker">
			{m.admin_sponsor_title()}
		</h1>
		<button
			type="button"
			onclick={openAddModal}
			class="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-primary px-5 py-2.5 font-chinese text-sm font-bold text-white shadow-sm transition-colors hover:bg-primary-dark"
		>
			<Plus class="h-4 w-4" />
			{m.admin_sponsor_add()}
		</button>
	</div>

	<!-- Filters -->
	<div class="flex items-center gap-4">
		<div class="flex rounded-xl border border-slate-200 bg-white p-1">
			{#each [
				{ key: 'all', label: m.admin_sponsor_filter_all() },
				{ key: 'confirmed', label: m.admin_sponsor_filter_confirmed() },
				{ key: 'unconfirmed', label: m.admin_sponsor_filter_unconfirmed() }
			] as tab}
				<button
					type="button"
					onclick={() => (statusFilter = tab.key as typeof statusFilter)}
					class="cursor-pointer rounded-lg px-4 py-2 font-chinese text-sm font-medium transition-all duration-200
					{statusFilter === tab.key
						? 'bg-primary text-white shadow-sm'
						: 'text-slate-500 hover:text-slate-700'}"
				>
					{tab.label}
				</button>
			{/each}
		</div>
		<span class="font-chinese text-sm text-slate-500">
			{m.admin_sponsor_total({ count: String(filteredSponsors.length) })}
		</span>
	</div>

	<!-- Sponsors List -->
	{#if filteredSponsors.length === 0}
		<div class="rounded-2xl border border-slate-100 bg-white py-16 text-center shadow-sm">
			<p class="font-chinese text-slate-400">{m.admin_sponsor_empty()}</p>
		</div>
	{:else}
		<div class="space-y-3">
			{#each filteredSponsors as sponsor (sponsor.id)}
				<div
					class="overflow-hidden rounded-2xl border border-slate-100 bg-white shadow-sm transition-shadow hover:shadow-md"
				>
					<div class="flex items-center gap-4 px-4 py-4 sm:px-6">
						<!-- Sort handle -->
						<div class="hidden text-slate-300 sm:block">
							<GripVertical class="h-5 w-5" />
						</div>

						<!-- Sponsor info -->
						<div class="min-w-0 flex-1">
							<div class="flex items-center gap-2">
								<span class="font-chinese text-sm font-bold text-slate-900">
									{sponsor.name_zh}
								</span>
								<span class="font-chinese text-sm text-slate-400">
									{sponsor.name_en}
								</span>
							</div>
							<div class="mt-1 flex flex-wrap items-center gap-2">
								<!-- Level badge -->
								<span
									class="inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold {levelColors[
										sponsor.level
									] ?? 'bg-slate-100 text-slate-600'}"
								>
									{levelLabels[sponsor.level]?.() ?? sponsor.level}
								</span>
								<!-- Website -->
								{#if sponsor.website}
									<a
										href={sponsor.website}
										target="_blank"
										rel="noopener noreferrer"
										class="inline-flex items-center gap-1 text-xs text-slate-400 transition-colors hover:text-primary"
									>
										<ExternalLink class="h-3 w-3" />
										{sponsor.website.replace(/^https?:\/\//, '').replace(/\/$/, '')}
									</a>
								{/if}
								<!-- Contact -->
								{#if sponsor.contact_name}
									<span class="text-xs text-slate-400">
										{sponsor.contact_name}
										{#if sponsor.contact_phone}· {sponsor.contact_phone}{/if}
									</span>
								{/if}
							</div>
						</div>

						<!-- Confirmed toggle -->
						<button
							type="button"
							onclick={() => toggleConfirmed(sponsor)}
							class="cursor-pointer shrink-0 rounded-full px-3 py-1.5 text-xs font-semibold transition-colors
							{sponsor.is_confirmed
								? 'bg-primary/10 text-primary hover:bg-primary/20'
								: 'bg-slate-100 text-slate-400 hover:bg-slate-200 hover:text-slate-600'}"
							title={m.admin_sponsor_toggle_confirm()}
						>
							{#if sponsor.is_confirmed}
								<Eye class="mr-1 inline h-3.5 w-3.5" />
								{m.admin_sponsor_confirmed()}
							{:else}
								<EyeOff class="mr-1 inline h-3.5 w-3.5" />
								{m.admin_sponsor_unconfirmed()}
							{/if}
						</button>

						<!-- Actions -->
						<div class="flex shrink-0 items-center gap-1">
							<button
								type="button"
								onclick={() => openEditModal(sponsor)}
								class="cursor-pointer rounded-lg p-2 text-slate-400 transition-colors hover:bg-slate-50 hover:text-primary"
								title={m.admin_sponsor_edit()}
							>
								<Pencil class="h-4 w-4" />
							</button>
							<button
								type="button"
								onclick={() => deleteSponsor(sponsor)}
								class="cursor-pointer rounded-lg p-2 text-slate-400 transition-colors hover:bg-danger/5 hover:text-danger"
								title={m.admin_sponsor_delete()}
							>
								<Trash2 class="h-4 w-4" />
							</button>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<!-- Add/Edit Modal -->
{#if modalOpen}
	<div class="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 pt-12">
		<!-- Backdrop -->
		<button
			type="button"
			class="fixed inset-0 bg-black/40 backdrop-blur-sm"
			onclick={closeModal}
			aria-label="Close"
		></button>

		<!-- Modal -->
		<div
			class="relative w-full max-w-lg rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl"
		>
			<button
				type="button"
				onclick={closeModal}
				class="absolute right-4 top-4 cursor-pointer p-1 text-slate-400 hover:text-slate-600"
			>
				<X class="h-5 w-5" />
			</button>

			<h3 class="mb-6 font-chinese text-lg font-bold text-slate-900">
				{editingSponsor ? m.admin_sponsor_edit() : m.admin_sponsor_add()}
			</h3>

			<form
				onsubmit={(e) => {
					e.preventDefault();
					saveSponsor();
				}}
				class="space-y-4"
			>
				<!-- Names row -->
				<div class="grid grid-cols-2 gap-3">
					<div>
						<label
							for="name_zh"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_name_zh()} *
						</label>
						<input
							id="name_zh"
							type="text"
							bind:value={form.name_zh}
							required
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
					<div>
						<label
							for="name_en"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_name_en()} *
						</label>
						<input
							id="name_en"
							type="text"
							bind:value={form.name_en}
							required
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
				</div>

				<!-- Level -->
				<div>
					<label
						for="level"
						class="mb-1 block font-chinese text-xs font-medium text-slate-600"
					>
						{m.admin_sponsor_level()}
					</label>
					<select
						id="level"
						bind:value={form.level}
						class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
					>
						{#each LEVELS as lvl}
							<option value={lvl}>{levelLabels[lvl]?.() ?? lvl}</option>
						{/each}
					</select>
				</div>

				<!-- Logo + Website row -->
				<div class="grid grid-cols-2 gap-3">
					<div>
						<label
							for="logo_url"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_logo_url()}
						</label>
						<input
							id="logo_url"
							type="url"
							bind:value={form.logo_url}
							placeholder="https://..."
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 placeholder:text-slate-300 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
					<div>
						<label
							for="website"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_website()}
						</label>
						<input
							id="website"
							type="url"
							bind:value={form.website}
							placeholder="https://..."
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 placeholder:text-slate-300 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
				</div>

				<!-- Contact row -->
				<div class="grid grid-cols-3 gap-3">
					<div>
						<label
							for="contact_name"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_contact_name()}
						</label>
						<input
							id="contact_name"
							type="text"
							bind:value={form.contact_name}
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
					<div>
						<label
							for="contact_phone"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_contact_phone()}
						</label>
						<input
							id="contact_phone"
							type="text"
							bind:value={form.contact_phone}
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
					<div>
						<label
							for="contact_email"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_contact_email()}
						</label>
						<input
							id="contact_email"
							type="email"
							bind:value={form.contact_email}
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
				</div>

				<!-- Descriptions -->
				<div class="grid grid-cols-2 gap-3">
					<div>
						<label
							for="desc_zh"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_desc_zh()}
						</label>
						<textarea
							id="desc_zh"
							bind:value={form.description_zh}
							rows="2"
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						></textarea>
					</div>
					<div>
						<label
							for="desc_en"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_desc_en()}
						</label>
						<textarea
							id="desc_en"
							bind:value={form.description_en}
							rows="2"
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						></textarea>
					</div>
				</div>

				<!-- Sort order + Confirmed row -->
				<div class="flex items-center gap-6">
					<div class="w-24">
						<label
							for="sort_order"
							class="mb-1 block font-chinese text-xs font-medium text-slate-600"
						>
							{m.admin_sponsor_sort_order()}
						</label>
						<input
							id="sort_order"
							type="number"
							bind:value={form.sort_order}
							class="w-full rounded-xl border border-slate-200 px-3 py-2.5 font-chinese text-sm text-slate-900 transition-all focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none"
						/>
					</div>
					<label class="flex cursor-pointer items-center gap-2 pt-4">
						<input
							type="checkbox"
							bind:checked={form.is_confirmed}
							class="h-4 w-4 rounded border-slate-300 text-primary accent-primary"
						/>
						<span class="font-chinese text-sm font-medium text-slate-700">
							{m.admin_sponsor_confirmed()}
						</span>
					</label>
				</div>

				<!-- Actions -->
				<div class="flex gap-3 pt-2">
					<button
						type="button"
						onclick={closeModal}
						class="flex-1 cursor-pointer rounded-xl border border-slate-200 py-3 font-chinese text-sm font-medium text-slate-600 transition-colors hover:bg-slate-50"
					>
						{m.admin_sponsor_cancel()}
					</button>
					<button
						type="submit"
						disabled={saving || !form.name_zh.trim() || !form.name_en.trim()}
						class="flex flex-1 cursor-pointer items-center justify-center gap-2 rounded-xl bg-primary py-3 font-chinese text-sm font-bold text-white transition-colors hover:bg-primary-dark disabled:cursor-not-allowed disabled:opacity-50"
					>
						{#if saving}
							<Loader2 class="h-4 w-4 animate-spin" />
						{/if}
						{m.admin_sponsor_save()}
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}
