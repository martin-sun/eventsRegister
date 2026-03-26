<script lang="ts">
	import '../layout.css';
	import {
		LayoutDashboard,
		ClipboardList,
		Handshake,
		LogOut,
		ExternalLink,
		Menu,
		X,
		Loader2
	} from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
	import { getLocale } from '$lib/paraglide/runtime.js';
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import { supabaseAuth } from '$lib/supabase-auth';
	import LanguageSwitcher from '$lib/components/LanguageSwitcher.svelte';

	let { children } = $props();

	let checking = $state(true);
	let user = $state<{ email?: string } | null>(null);
	let sidebarOpen = $state(false);

	// Check if we're on the login page
	let isLoginPage = $derived(page.url.pathname === '/admin/login');

	$effect(() => {
		document.documentElement.lang = getLocale();
	});

	// Auth check on mount
	$effect(() => {
		if (isLoginPage) {
			checking = false;
			return;
		}

		supabaseAuth.auth.getSession().then(({ data }) => {
			const session = data.session;
			if (!session) {
				goto('/admin/login');
				return;
			}
			const role = session.user?.app_metadata?.role;
			if (role !== 'admin') {
				supabaseAuth.auth.signOut();
				goto('/admin/login');
				return;
			}
			user = { email: session.user.email };
			checking = false;
		});
	});

	async function handleLogout() {
		await supabaseAuth.auth.signOut();
		goto('/admin/login');
	}

	const navItems = $derived([
		{ label: m.admin_nav_dashboard(), href: '/admin', icon: LayoutDashboard },
		{ label: m.admin_nav_registrations(), href: '/admin/registrations', icon: ClipboardList }
	]);

	function isActive(href: string): boolean {
		if (href === '/admin') return page.url.pathname === '/admin';
		return page.url.pathname.startsWith(href);
	}
</script>

{#if isLoginPage}
	{@render children()}
{:else if checking}
	<div class="flex min-h-screen items-center justify-center bg-slate-50">
		<Loader2 class="h-8 w-8 animate-spin text-primary" />
	</div>
{:else}
	<div class="flex min-h-screen bg-slate-50">
		<!-- Sidebar (desktop) -->
		<aside class="hidden w-64 flex-col border-r border-slate-200 bg-white lg:flex">
			<!-- Logo -->
			<div class="flex items-center gap-3 border-b border-slate-100 px-6 py-5">
				<div class="flex h-10 w-10 items-center justify-center rounded-xl bg-primary font-heading text-lg text-white">
					BC
				</div>
				<div>
					<div class="font-chinese text-sm font-bold text-primary-darker leading-tight">
						{m.admin_nav_dashboard()}
					</div>
					<div class="font-chinese text-xs text-slate-500 leading-tight">{user?.email ?? ''}</div>
				</div>
			</div>

			<!-- Nav -->
			<nav class="flex-1 space-y-1 px-3 py-4">
				{#each navItems as item}
					<a
						href={item.href}
						class="flex items-center gap-3 rounded-xl px-4 py-3 font-chinese text-sm font-medium transition-all duration-200
						{isActive(item.href)
							? 'bg-primary/10 text-primary'
							: 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'}"
					>
						<item.icon class="h-5 w-5" />
						{item.label}
					</a>
				{/each}
			</nav>

			<!-- Bottom -->
			<div class="border-t border-slate-100 px-3 py-4 space-y-1">
				<a
					href="/"
					class="flex items-center gap-3 rounded-xl px-4 py-3 font-chinese text-sm text-slate-500 transition-colors hover:bg-slate-50 hover:text-slate-700"
				>
					<ExternalLink class="h-5 w-5" />
					{m.admin_nav_back_site()}
				</a>
				<button
					type="button"
					onclick={handleLogout}
					class="flex w-full cursor-pointer items-center gap-3 rounded-xl px-4 py-3 font-chinese text-sm text-slate-500 transition-colors hover:bg-danger/5 hover:text-danger"
				>
					<LogOut class="h-5 w-5" />
					{m.admin_nav_logout()}
				</button>
			</div>
		</aside>

		<!-- Mobile header -->
		<div class="flex flex-1 flex-col">
			<header class="flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3 lg:hidden">
				<button
					type="button"
					onclick={() => (sidebarOpen = !sidebarOpen)}
					class="cursor-pointer rounded-lg p-2 text-slate-600 hover:bg-slate-100"
				>
					{#if sidebarOpen}
						<X class="h-6 w-6" />
					{:else}
						<Menu class="h-6 w-6" />
					{/if}
				</button>
				<div class="font-chinese text-sm font-bold text-primary-darker">{m.admin_nav_dashboard()}</div>
				<LanguageSwitcher />
			</header>

			<!-- Mobile sidebar overlay -->
			{#if sidebarOpen}
				<div class="fixed inset-0 z-40 lg:hidden">
					<!-- Backdrop -->
					<button
						type="button"
						class="fixed inset-0 bg-black/30"
						onclick={() => (sidebarOpen = false)}
						aria-label="Close sidebar"
					></button>
					<!-- Drawer -->
					<aside class="fixed left-0 top-0 z-50 flex h-full w-64 flex-col border-r border-slate-200 bg-white shadow-xl">
						<div class="flex items-center justify-between border-b border-slate-100 px-6 py-5">
							<div class="font-chinese text-sm font-bold text-primary-darker">{m.admin_nav_dashboard()}</div>
							<button type="button" onclick={() => (sidebarOpen = false)} class="cursor-pointer p-1 text-slate-400">
								<X class="h-5 w-5" />
							</button>
						</div>
						<nav class="flex-1 space-y-1 px-3 py-4">
							{#each navItems as item}
								<a
									href={item.href}
									onclick={() => (sidebarOpen = false)}
									class="flex items-center gap-3 rounded-xl px-4 py-3 font-chinese text-sm font-medium transition-all duration-200
									{isActive(item.href)
										? 'bg-primary/10 text-primary'
										: 'text-slate-600 hover:bg-slate-50'}"
								>
									<item.icon class="h-5 w-5" />
									{item.label}
								</a>
							{/each}
						</nav>
						<div class="border-t border-slate-100 px-3 py-4 space-y-1">
							<a href="/" class="flex items-center gap-3 rounded-xl px-4 py-3 font-chinese text-sm text-slate-500 hover:bg-slate-50">
								<ExternalLink class="h-5 w-5" />
								{m.admin_nav_back_site()}
							</a>
							<button
								type="button"
								onclick={handleLogout}
								class="flex w-full cursor-pointer items-center gap-3 rounded-xl px-4 py-3 font-chinese text-sm text-slate-500 hover:bg-danger/5 hover:text-danger"
							>
								<LogOut class="h-5 w-5" />
								{m.admin_nav_logout()}
							</button>
						</div>
					</aside>
				</div>
			{/if}

			<!-- Main content -->
			<main class="flex-1 overflow-auto p-4 sm:p-6 lg:p-8">
				{@render children()}
			</main>
		</div>
	</div>
{/if}
