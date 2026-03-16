<script lang="ts">
	import { Mail, Phone, MapPin } from 'lucide-svelte';
</script>

<footer class="border-t border-slate-200 bg-primary-darker text-white">
	<!-- Sponsor strip -->
	<div class="border-b border-white/10 bg-primary-darker px-4 py-6">
		<div class="mx-auto max-w-7xl text-center">
			<p class="mb-3 font-chinese text-xs tracking-wider text-white/60 uppercase">合作赞助商</p>
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
				<h3 class="mb-3 font-heading text-xl tracking-wide">萨斯卡通羽毛球双打锦标赛</h3>
				<p class="font-chinese text-sm leading-relaxed text-white/70">
					面向萨斯卡通所有羽毛球爱好者的年度双打赛事，促进社区交流，享受运动乐趣。
				</p>
			</div>

			<!-- Contact -->
			<div>
				<h3 class="mb-3 font-heading text-xl tracking-wide">联系我们</h3>
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
				<h3 class="mb-3 font-heading text-xl tracking-wide">快速链接</h3>
				<div class="space-y-2">
					<a
						href="/register"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>立即报名</a
					>
					<a
						href="/#rules"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>赛制规则</a
					>
					<a
						href="/teams"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>参赛队伍</a
					>
					<a
						href="/#sponsors"
						class="block cursor-pointer font-chinese text-sm text-white/70 transition-colors duration-200 hover:text-cta"
						>赞助商</a
					>
				</div>
			</div>
		</div>
	</div>

	<!-- Copyright -->
	<div class="border-t border-white/10 px-4 py-4">
		<p class="text-center font-chinese text-xs text-white/50">
			&copy; 2026 萨斯卡通羽毛球双打锦标赛组委会. All rights reserved.
		</p>
	</div>
</footer>
