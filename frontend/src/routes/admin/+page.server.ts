import type { PageServerLoad } from './$types';
import { supabase } from '$lib/supabase';
import type { CategoryStat } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [categoryResult, recentTeamsResult] = await Promise.all([
		supabase.from('category_stats').select('*'),
		supabase
			.from('teams_detail')
			.select('*')
			.order('created_at', { ascending: false })
			.limit(10)
	]);

	return {
		categories: (categoryResult.data ?? []) as CategoryStat[],
		recentTeams: recentTeamsResult.data ?? []
	};
};
