import type { PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import { getTournamentConfig } from '$lib/server/config';
import type { CategoryStat, Sponsor } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [categoryResult, sponsorResult, config] = await Promise.all([
		supabaseAdmin.from('category_stats').select('*'),
		supabaseAdmin
			.from('sponsors')
			.select(
				'id, name_zh, name_en, level, logo_url, website, description_zh, description_en, sort_order'
			)
			.eq('is_confirmed', true)
			.order('sort_order'),
		getTournamentConfig()
	]);

	return {
		categories: (categoryResult.data ?? []) as CategoryStat[],
		sponsors: (sponsorResult.data ?? []) as Sponsor[],
		config
	};
};
