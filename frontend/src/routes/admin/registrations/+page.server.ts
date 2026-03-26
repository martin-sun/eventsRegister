import type { PageServerLoad } from './$types';
import { supabase } from '$lib/supabase';
import { getTournamentConfig } from '$lib/server/config';
import type { AdminTeam } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [teamsResult, config] = await Promise.all([
		supabase
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
