import type { PageServerLoad } from './$types';
import { getTournamentConfig } from '$lib/server/config';

export const load: PageServerLoad = async () => {
	const config = await getTournamentConfig();
	return { config };
};
