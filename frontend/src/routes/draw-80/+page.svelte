<script lang="ts">
	import { ChevronLeft } from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
</script>

<svelte:head>
	<title>{m.draw_80_title()} | {m.site_title()}</title>
</svelte:head>

<section class="min-h-screen bg-surface py-8 sm:py-12">
	<div class="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
		<!-- Header -->
		<div class="mb-6 flex items-center gap-4">
			<a
				href="/"
				class="inline-flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-4 py-2 font-chinese text-sm font-medium text-slate-600 shadow-sm transition-all duration-200 hover:border-slate-300 hover:bg-slate-50"
			>
				<ChevronLeft class="h-4 w-4" />
				{m.back_home()}
			</a>
			<h1 class="font-heading text-2xl tracking-wide text-primary-darker sm:text-3xl">
				{m.draw_80_title()}
			</h1>
		</div>

		<!-- PDF Viewer -->
		<div class="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-lg">
			<iframe
				src="/pdfs/Double%2080+%20Draw.pdf"
				class="h-[80vh] w-full"
				title={m.draw_80_title()}
			></iframe>
		</div>
	</div>
</section>
