<script lang="ts">
	import '../../layout.css';
	import { getLocale } from '$lib/paraglide/runtime.js';

	let { children } = $props();

	$effect(() => {
		document.documentElement.lang = getLocale();
	});
</script>

{@render children()}
