import type { PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import type { CategoryStat } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [categoryResult, recentTeamsResult] = await Promise.all([
		supabaseAdmin.from('category_stats').select('*'),
		supabaseAdmin
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
