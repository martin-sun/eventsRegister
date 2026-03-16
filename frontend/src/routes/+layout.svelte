<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import Header from '$lib/components/Header.svelte';
	import Footer from '$lib/components/Footer.svelte';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<meta name="description" content="萨斯卡通羽毛球双打锦标赛 - Saskatoon Badminton Doubles Championship 2026" />
</svelte:head>

<div class="flex min-h-screen flex-col">
	<Header />
	<main class="flex-1 pt-16">
		{@render children()}
	</main>
	<Footer />
</div>
