import type { PageServerLoad } from './$types';
import { supabase } from '$lib/supabase';
import type { CategoryStat, PublicTeam } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [teamsResult, categoryResult] = await Promise.all([
		supabase.rpc('get_public_teams'),
		supabase.from('category_stats').select('*')
	]);

	return {
		teams: (teamsResult.data ?? []) as PublicTeam[],
		categories: (categoryResult.data ?? []) as CategoryStat[]
	};
};
