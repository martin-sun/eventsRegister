<script lang="ts">
	import { m } from '$lib/paraglide/messages.js';

	let { value = $bindable(''), id = '', class: className = '', hasError = false, onBlur }: Props = $props();

	type Props = {
		value?: string;
		id?: string;
		class?: string;
		hasError?: boolean;
		onBlur?: () => void;
	};

	let year = $state('');
	let month = $state('');
	let day = $state('');

	let yearRef: HTMLInputElement | undefined = $state();
	let monthRef: HTMLInputElement | undefined = $state();
	let dayRef: HTMLInputElement | undefined = $state();

	let openDropdown: 'year' | 'month' | 'day' | null = $state(null);
	let containerRef: HTMLDivElement | undefined = $state();

	const currentYear = new Date().getFullYear();
	const yearOptions = Array.from({ length: currentYear - 1900 + 1 }, (_, i) => String(currentYear - i));
	const monthNames = [
		m.dob_month_jan(), m.dob_month_feb(), m.dob_month_mar(), m.dob_month_apr(),
		m.dob_month_may(), m.dob_month_jun(), m.dob_month_jul(), m.dob_month_aug(),
		m.dob_month_sep(), m.dob_month_oct(), m.dob_month_nov(), m.dob_month_dec()
	];

	let maxDay = $derived.by(() => {
		if (year && month) {
			return new Date(Number(year), Number(month), 0).getDate();
		}
		return 31;
	});
	let dayOptions = $derived(Array.from({ length: maxDay }, (_, i) => String(i + 1)));

	// Sync internal fields → value (YYYY-MM-DD)
	$effect(() => {
		if (year.length === 4 && month.length >= 1 && day.length >= 1) {
			const mm = month.padStart(2, '0');
			const dd = day.padStart(2, '0');
			const next = `${year}-${mm}-${dd}`;
			if (next !== value) value = next;
		} else if (year || month || day) {
			if (value) value = '';
		}
	});

	// Sync external value → internal fields
	$effect(() => {
		if (!value) {
			year = '';
			month = '';
			day = '';
			return;
		}
		const parts = value.split('-');
		if (parts.length === 3) {
			if (parts[0] !== year) year = parts[0];
			if (parts[1] !== month) month = String(Number(parts[1]));
			if (parts[2] !== day) day = String(Number(parts[2]));
		}
	});

	// Close dropdown on outside click
	$effect(() => {
		function handler(e: MouseEvent) {
			if (containerRef && !containerRef.contains(e.target as Node)) {
				openDropdown = null;
			}
		}
		document.addEventListener('mousedown', handler);
		return () => document.removeEventListener('mousedown', handler);
	});

	function clamp(input: string, min: number, max: number): string {
		if (!input) return '';
		let n = parseInt(input, 10);
		if (isNaN(n)) return '';
		if (n > max) n = max;
		if (n < min) n = min;
		return String(n);
	}

	function handleYearInput(e: Event) {
		const el = e.target as HTMLInputElement;
		el.value = el.value.replace(/\D/g, '').slice(0, 4);
		year = el.value;
		if (year.length === 4) monthRef?.focus();
	}

	function handleMonthInput(e: Event) {
		const el = e.target as HTMLInputElement;
		el.value = el.value.replace(/\D/g, '').slice(0, 2);
		month = el.value;
		if (month.length === 2) dayRef?.focus();
	}

	function handleDayInput(e: Event) {
		const el = e.target as HTMLInputElement;
		el.value = el.value.replace(/\D/g, '').slice(0, 2);
		day = el.value;
	}

	function handleYearBlur() {
		year = clamp(year, 1900, currentYear);
		triggerBlur();
	}

	function handleMonthBlur() {
		month = clamp(month, 1, 12);
		triggerBlur();
	}

	function handleDayBlur() {
		day = clamp(day, 1, maxDay);
		triggerBlur();
	}

	function handleKeydown(field: 'year' | 'month' | 'day', e: KeyboardEvent) {
		if (e.key === 'Escape') {
			openDropdown = null;
			return;
		}
		if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
			e.preventDefault();
			if (openDropdown !== field) openDropdown = field;
			const list = containerRef?.querySelector(`[data-list="${field}"]`);
			if (list) {
				const items = list.querySelectorAll('[data-item]');
				const focused = list.querySelector('[data-focused="true"]');
				let idx = focused ? Array.from(items).indexOf(focused) : -1;
				focused?.removeAttribute('data-focused');
				if (e.key === 'ArrowDown') idx = Math.min(idx + 1, items.length - 1);
				else idx = Math.max(idx - 1, 0);
				(items[idx] as HTMLElement)?.focus();
				items[idx]?.setAttribute('data-focused', 'true');
			}
			return;
		}
		if (field === 'year' && (e.key === 'Enter' || e.key === 'Tab') && year.length === 4) {
			openDropdown = null;
			monthRef?.focus();
		}
		if (field === 'month' && (e.key === 'Enter' || e.key === 'Tab') && month.length >= 1) {
			openDropdown = null;
			dayRef?.focus();
		}
		if (field === 'day' && e.key === 'Enter') {
			openDropdown = null;
		}
	}

	function selectYear(y: string) {
		year = y;
		openDropdown = null;
		monthRef?.focus();
	}

	function selectMonth(mo: string) {
		month = mo;
		openDropdown = null;
		dayRef?.focus();
	}

	function selectDay(d: string) {
		day = d;
		openDropdown = null;
		dayRef?.blur();
		triggerBlur();
	}

	let blurTimer: ReturnType<typeof setTimeout> | undefined;
	function triggerBlur() {
		clearTimeout(blurTimer);
		blurTimer = setTimeout(() => {
			if (onBlur) onBlur();
		}, 100);
	}

	const baseInput =
		'w-full rounded-xl border border-slate-200 text-center text-base text-slate-900 transition-all duration-200 focus:border-primary focus:ring-2 focus:ring-primary/20 focus:outline-none';
	const errorCls = 'border-danger ring-2 ring-danger/20';
</script>

<div class="relative flex items-center gap-2" {id} bind:this={containerRef}>
	<!-- Year -->
	<div class="relative" style="width:5.5rem">
		<input
			type="text"
			inputmode="numeric"
			bind:this={yearRef}
			value={year}
			oninput={handleYearInput}
			onblur={handleYearBlur}
			onkeydown={(e) => handleKeydown('year', e)}
			onfocus={() => (openDropdown = 'year')}
			placeholder={m.dob_year()}
			maxlength="4"
			class="{baseInput} px-2 py-3 {hasError ? errorCls : ''} {className}"
			aria-label={m.dob_year()}
		/>
		<!-- Dropdown arrow indicator -->
		<button
			type="button"
			tabindex="-1"
			aria-label="Select year"
			onclick={() => { openDropdown = openDropdown === 'year' ? null : 'year'; yearRef?.focus(); }}
			class="absolute right-1.5 top-1/2 -translate-y-1/2 p-0.5 text-slate-300 hover:text-slate-500 transition-colors"
		>
			<svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd"/></svg>
		</button>
		{#if openDropdown === 'year'}
			<ul
				data-list="year"
				class="absolute left-0 z-50 mt-1 max-h-48 w-full overflow-auto rounded-xl border border-slate-200 bg-white py-1 shadow-lg"
			>
				{#each yearOptions as y}
					<li>
						<button
							type="button"
							data-item
							onclick={() => selectYear(y)}
							class="w-full cursor-pointer px-3 py-1.5 text-center text-sm transition-colors hover:bg-primary/10 hover:text-primary {y === year ? 'bg-primary/5 font-bold text-primary' : 'text-slate-700'}"
						>
							{y}
						</button>
					</li>
				{/each}
			</ul>
		{/if}
	</div>

	<span class="text-slate-300 font-bold text-lg select-none">/</span>

	<!-- Month -->
	<div class="relative" style="width:4rem">
		<input
			type="text"
			inputmode="numeric"
			bind:this={monthRef}
			value={month}
			oninput={handleMonthInput}
			onblur={handleMonthBlur}
			onkeydown={(e) => handleKeydown('month', e)}
			onfocus={() => (openDropdown = 'month')}
			placeholder={m.dob_month()}
			maxlength="2"
			class="{baseInput} px-2 py-3 {hasError ? errorCls : ''} {className}"
			aria-label={m.dob_month()}
		/>
		<button
			type="button"
			tabindex="-1"
			aria-label="Select month"
			onclick={() => { openDropdown = openDropdown === 'month' ? null : 'month'; monthRef?.focus(); }}
			class="absolute right-1 top-1/2 -translate-y-1/2 p-0.5 text-slate-300 hover:text-slate-500 transition-colors"
		>
			<svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd"/></svg>
		</button>
		{#if openDropdown === 'month'}
			<ul
				data-list="month"
				class="absolute left-0 z-50 mt-1 w-full overflow-auto rounded-xl border border-slate-200 bg-white py-1 shadow-lg"
			>
				{#each monthNames as name, i}
					{@const mo = String(i + 1)}
					<li>
						<button
							type="button"
							data-item
							onclick={() => selectMonth(mo)}
							class="w-full cursor-pointer px-3 py-1.5 text-center text-sm transition-colors hover:bg-primary/10 hover:text-primary {mo === month ? 'bg-primary/5 font-bold text-primary' : 'text-slate-700'}"
						>
							{name}
						</button>
					</li>
				{/each}
			</ul>
		{/if}
	</div>

	<span class="text-slate-300 font-bold text-lg select-none">/</span>

	<!-- Day -->
	<div class="relative" style="width:4rem">
		<input
			type="text"
			inputmode="numeric"
			bind:this={dayRef}
			value={day}
			oninput={handleDayInput}
			onblur={handleDayBlur}
			onkeydown={(e) => handleKeydown('day', e)}
			onfocus={() => (openDropdown = 'day')}
			placeholder={m.dob_day()}
			maxlength="2"
			class="{baseInput} px-2 py-3 {hasError ? errorCls : ''} {className}"
			aria-label={m.dob_day()}
		/>
		<button
			type="button"
			tabindex="-1"
			aria-label="Select day"
			onclick={() => { openDropdown = openDropdown === 'day' ? null : 'day'; dayRef?.focus(); }}
			class="absolute right-1 top-1/2 -translate-y-1/2 p-0.5 text-slate-300 hover:text-slate-500 transition-colors"
		>
			<svg class="h-3.5 w-3.5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd"/></svg>
		</button>
		{#if openDropdown === 'day'}
			<ul
				data-list="day"
				class="absolute left-0 z-50 mt-1 max-h-48 w-full overflow-auto rounded-xl border border-slate-200 bg-white py-1 shadow-lg"
			>
				{#each dayOptions as d}
					<li>
						<button
							type="button"
							data-item
							onclick={() => selectDay(d)}
							class="w-full cursor-pointer px-3 py-1.5 text-center text-sm transition-colors hover:bg-primary/10 hover:text-primary {d === day ? 'bg-primary/5 font-bold text-primary' : 'text-slate-700'}"
						>
							{d}
						</button>
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</div>
