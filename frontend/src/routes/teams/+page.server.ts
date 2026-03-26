import type { PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import type { CategoryStat, PublicTeam } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [teamsResult, categoryResult] = await Promise.all([
		supabaseAdmin.rpc('get_public_teams'),
		supabaseAdmin.from('category_stats').select('*')
	]);

	return {
		teams: (teamsResult.data ?? []) as PublicTeam[],
		categories: (categoryResult.data ?? []) as CategoryStat[]
	};
};
