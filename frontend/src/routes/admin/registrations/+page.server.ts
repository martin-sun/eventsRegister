import type { PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import { getTournamentConfig } from '$lib/server/config';
import type { AdminTeam } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [teamsResult, config] = await Promise.all([
		supabaseAdmin
			.from('teams_detail')
			.select('*')
			.order('created_at', { ascending: false }),
		getTournamentConfig()
	]);

	return {
		teams: (teamsResult.data ?? []) as AdminTeam[],
		config
	};
};
