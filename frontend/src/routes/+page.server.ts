import type { PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import type { CategoryStat } from '$lib/types';

export const load: PageServerLoad = async () => {
	const categoryResult = await supabaseAdmin.from('category_stats').select('*');

	return {
		categories: (categoryResult.data ?? []) as CategoryStat[]
	};
};
