import type { LayoutServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import { getTournamentConfig } from '$lib/server/config';
import type { Sponsor } from '$lib/types';

export const load: LayoutServerLoad = async () => {
	const [sponsorResult, config] = await Promise.all([
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
		sponsors: (sponsorResult.data ?? []) as Sponsor[],
		config
	};
};
