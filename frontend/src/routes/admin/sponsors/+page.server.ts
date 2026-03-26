import type { PageServerLoad } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';

export const load: PageServerLoad = async () => {
	const { data, error } = await supabaseAdmin
		.from('sponsors')
		.select('*')
		.order('sort_order');

	return {
		sponsors: data ?? []
	};
};
