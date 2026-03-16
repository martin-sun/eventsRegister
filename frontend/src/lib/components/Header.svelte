<script lang="ts">
	import { Menu, X, Globe } from 'lucide-svelte';

	let mobileMenuOpen = $state(false);

	const navItems = [
		{ label: '首页', href: '/' },
		{ label: '报名', href: '/register' },
		{ label: '队伍', href: '/teams' },
		{ label: '规则', href: '/rules' },
		{ label: '赞助', href: '/sponsors' }
	];

	function toggleMobileMenu() {
		mobileMenuOpen = !mobileMenuOpen;
	}
</script>

<header class="fixed top-0 right-0 left-0 z-50 bg-white/95 shadow-sm backdrop-blur-sm">
	<div class="mx-auto flex max-w-7xl items-center justify-between px-4 py-3 sm:px-6 lg:px-8">
		<!-- Logo + Event Name -->
		<a href="/" class="flex items-center gap-2">
			<div
				class="flex h-10 w-10 items-center justify-center rounded-lg bg-primary font-heading text-lg text-white"
			>
				BC
			</div>
			<div class="hidden sm:block">
				<div class="font-chinese text-sm font-bold text-primary-darker leading-tight">
					萨斯卡通羽毛球
				</div>
				<div class="font-chinese text-xs text-slate-500 leading-tight">双打锦标赛</div>
			</div>
		</a>

		<!-- Desktop Navigation -->
		<nav class="hidden items-center gap-1 md:flex">
			{#each navItems as item}
				<a
					href={item.href}
					class="cursor-pointer rounded-lg px-4 py-2 font-chinese text-sm font-medium text-slate-700 transition-colors duration-200 hover:bg-surface hover:text-primary"
				>
					{item.label}
				</a>
			{/each}
		</nav>

		<!-- Right: Language Switcher + Mobile Menu -->
		<div class="flex items-center gap-2">
			<button
				type="button"
				class="flex cursor-pointer items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-600 transition-colors duration-200 hover:border-primary hover:text-primary"
			>
				<Globe class="h-4 w-4" />
				<span class="font-chinese text-xs">中/EN</span>
			</button>

			<!-- Mobile menu button -->
			<button
				type="button"
				class="cursor-pointer rounded-lg p-2 text-slate-600 transition-colors duration-200 hover:bg-surface hover:text-primary md:hidden"
				onclick={toggleMobileMenu}
				aria-label="Toggle menu"
				aria-expanded={mobileMenuOpen}
			>
				{#if mobileMenuOpen}
					<X class="h-6 w-6" />
				{:else}
					<Menu class="h-6 w-6" />
				{/if}
			</button>
		</div>
	</div>

	<!-- Mobile Navigation -->
	{#if mobileMenuOpen}
		<nav class="border-t border-slate-100 bg-white px-4 py-3 md:hidden">
			{#each navItems as item}
				<a
					href={item.href}
					class="block cursor-pointer rounded-lg px-4 py-3 font-chinese text-base font-medium text-slate-700 transition-colors duration-200 hover:bg-surface hover:text-primary"
					onclick={() => (mobileMenuOpen = false)}
				>
					{item.label}
				</a>
			{/each}
		</nav>
	{/if}
</header>
