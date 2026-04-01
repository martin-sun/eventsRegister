<script lang="ts">
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import { Camera } from 'lucide-svelte';

	let { data } = $props();

	let eventName = $derived(getLocale() === 'zh' ? data.config.event_name.zh : data.config.event_name.en);
	let venueName = $derived(getLocale() === 'zh' ? data.config.venue.zh : data.config.venue.en);

	let eventDate = $derived(new Date(data.config.tournament_date));
	let formattedDate = $derived(() => {
		if (getLocale() === 'zh') {
			return eventDate.toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric' });
		}
		return eventDate.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
	});
</script>

<svelte:head>
	<title>{m.media_page_title({ eventName })}</title>
</svelte:head>

<section class="bg-white py-12 sm:py-16">
	<div class="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
		<!-- Header -->
		<div class="mb-10 text-center">
			<div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-cta/10 text-cta">
				<Camera class="h-7 w-7" />
			</div>
			<h1 class="mb-2 font-heading text-3xl tracking-wide text-primary-darker sm:text-4xl">
				{m.media_title()}
			</h1>
		</div>

		<!-- Event Info Card -->
		<div class="mb-8 rounded-2xl border border-slate-100 bg-surface p-6">
			<div class="space-y-1 font-chinese text-sm text-slate-600">
				<p class="font-semibold text-slate-800">{m.media_event_info({ eventName })}</p>
				<p>{m.media_event_date({ date: formattedDate() })}</p>
				<p>{m.media_event_location({ venue: venueName })}</p>
				<p>{m.media_event_address({ address: data.config.venue_address })}</p>
			</div>
		</div>

		<!-- Content Sections -->
		<div class="space-y-8">
			<div>
				<h2 class="mb-3 font-chinese text-lg font-bold text-slate-900">{m.media_section_consent_title()}</h2>
				<p class="mb-4 font-chinese text-sm leading-relaxed text-slate-600">
					{m.media_section_consent({ eventName })}
				</p>
				<p class="font-chinese text-sm leading-relaxed text-slate-600">
					{m.media_section_consent_2()}
				</p>
			</div>

			<div>
				<h2 class="mb-3 font-chinese text-lg font-bold text-slate-900">{m.media_section_release_title()}</h2>
				<p class="font-chinese text-sm leading-relaxed text-slate-600">
					{m.media_section_release()}
				</p>
			</div>
		</div>

		<!-- Acceptance Note -->
		<div class="mt-10 rounded-2xl border border-cta/20 bg-cta/5 p-6">
			<p class="font-chinese text-sm font-medium text-primary-darker">
				{m.media_acceptance()}
			</p>
		</div>
	</div>
</section>
