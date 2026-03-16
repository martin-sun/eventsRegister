<script lang="ts">
	import { Mail, Phone, MapPin } from 'lucide-svelte';
	import { m } from '$lib/paraglide/messages.js';
</script>

<footer class="border-t border-slate-200 bg-primary-darker text-white">
	<!-- Sponsor strip -->
	<div class="border-b border-white/10 bg-primary-darker px-4 py-6">
		<div class="mx-auto max-w-7xl text-center">
			<p class="mb-3 font-chinese text-xs tracking-wider text-white/60 uppercase">{m.footer_sponsors_label()}</p>
			<div class="flex flex-wrap items-center justify-center gap-8">
				<span class="font-chinese text-sm text-white/80">林与唐地产</span>
				<span class="font-chinese text-sm text-white/80">赞助商 B</span>
				<span class="font-chinese text-sm text-white/80">赞助商 C</span>
				<span class="font-chinese text-sm text-white/80">赞助商 D</span>
			</div>
		</div>
	</div>

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
						<span class="font-chinese text-sm text-white/70">badminton@saskatoon.example</span>
					</div>
					<div class="flex items-center gap-2">
						<Phone class="h-4 w-4 text-white/60" />
						<span class="font-chinese text-sm text-white/70">+1 (306) 555-0123</span>
					</div>
					<div class="flex items-center gap-2">
						<MapPin class="h-4 w-4 text-white/60" />
						<span class="font-chinese text-sm text-white/70"
							>Riverside Badminton & Tennis Club</span
						>
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
