<script lang="ts">
	import { getLocale, setLocale, locales } from '$lib/paraglide/runtime.js';

	const labels: Record<string, string> = {
		zh: '中文',
		en: 'EN'
	};

	function switchLocale(locale: string) {
		setLocale(locale as 'zh' | 'en');
	}
</script>

<div class="flex gap-1">
	{#each locales as locale}
		<button
			type="button"
			class="cursor-pointer rounded-md px-2.5 py-1.5 text-xs font-medium transition-colors duration-200
				{getLocale() === locale
				? 'bg-primary text-white'
				: 'text-slate-500 hover:bg-slate-100 hover:text-slate-700'}"
			onclick={() => switchLocale(locale)}
		>
			{labels[locale]}
		</button>
	{/each}
</div>
