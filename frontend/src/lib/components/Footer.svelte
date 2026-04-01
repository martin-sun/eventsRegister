<script lang="ts">
	import { Mail, Phone, MapPin } from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import type { TournamentConfig, Sponsor } from '$lib/types';

	let { config, sponsors }: { config: TournamentConfig; sponsors: Sponsor[] } = $props();

	let venueName = $derived(getLocale() === 'zh' ? config.venue.zh : config.venue.en);

	const sponsorLevelOrder = ['title', 'diamond', 'platinum', 'gold', 'friend', 'media'] as const;

	let topSponsors = $derived(
		sponsorLevelOrder
			.flatMap((level) => sponsors.filter((s) => s.level === level))
			.slice(0, 6)
	);

	function sponsorName(s: { name_zh: string; name_en: string }): string {
		return getLocale() === 'zh' ? s.name_zh : s.name_en;
	}
</script>

<footer class="border-t border-slate-200 bg-primary-darker text-white">
	<!-- Sponsor strip -->
	{#if topSponsors.length > 0}
		<div class="border-b border-white/10 bg-primary-darker px-4 py-6">
			<div class="mx-auto max-w-7xl text-center">
				<p class="mb-3 font-chinese text-xs tracking-wider text-white/60 uppercase">{m.footer_sponsors_label()}</p>
				<div class="flex flex-wrap items-center justify-center gap-8">
					{#each topSponsors as s}
						<span class="font-chinese text-sm text-white/80">{sponsorName(s)}</span>
					{/each}
				</div>
			</div>
		</div>
	{/if}

	<!-- Main footer -->
	<div class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
		<div class="grid gap-8 md:grid-cols-3">
			<!-- About -->
			<div>
				<h3 class="mb-3 font-heading text-xl tracking-wide">{m.footer_about_title()}</h3>
				<p class="font-chinese text-sm leading-relaxed text-white/70">
					{m.footer_about_desc()}
				</p>
			</div>

			<!-- Contact -->
			<div>
				<h3 class="mb-3 font-heading text-xl tracking-wide">{m.footer_contact_title()}</h3>
				<div class="space-y-2">
					<div class="flex items-center gap-2">
						<Mail class="h-4 w-4 text-white/60" />
						<span class="font-chinese text-sm text-white/70">{config.etransfer_email}</span>
					</div>
					<div class="flex items-center gap-2">
						<Phone class="h-4 w-4 text-white/60" />
						<span class="font-chinese text-sm text-white/70">{config.contact_phone}</span>
					</div>
					<div class="flex items-center gap-2">
						<MapPin class="h-4 w-4 text-white/60" />
						<span class="font-chinese text-sm text-white/70">{venueName}</span>
					</div>
				</div>
			</div>

			<!-- Quick Links -->
			<div>
				<h3 class="mb-3 font-heading text-xl tracking-wide">{m.footer_links_title()}</h3>
				<div class="space-y-2">
					<a
						href="/register"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>{m.footer_link_register()}</a
					>
					<a
						href="/#rules"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>{m.footer_link_rules()}</a
					>
					<a
						href="/teams"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>{m.footer_link_teams()}</a
					>
					<a
						href="/#sponsors"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>{m.footer_link_sponsors()}</a
					>
				</div>
			</div>
		</div>
	</div>

	<!-- Copyright -->
	<div class="border-t border-white/10 px-4 py-4">
		<p class="text-center font-chinese text-xs text-white/50">
			{m.footer_copyright()}
		</p>
	</div>
</footer>
