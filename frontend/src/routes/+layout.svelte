<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import Header from '$lib/components/Header.svelte';
	import Footer from '$lib/components/Footer.svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';

	let { children, data } = $props();

	$effect(() => {
		document.documentElement.lang = getLocale();
	});
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<meta name="description" content={m.site_subtitle()} />
</svelte:head>

<div class="flex min-h-screen flex-col">
	<Header />
	<main class="flex-1 pt-16">
		{@render children()}
	</main>
	<Footer config={data.config} sponsors={data.sponsors} />
</div>
