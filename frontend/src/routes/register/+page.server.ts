import type { PageServerLoad, Actions } from './$types';
import { supabase } from '$lib/supabase';
import { getTournamentConfig } from '$lib/server/config';
import { parseRegistrationError } from '$lib/server/registration';
import { fail } from '@sveltejs/kit';
import type { Category } from '$lib/types';

export const load: PageServerLoad = async () => {
	const [categoryResult, config] = await Promise.all([
		supabase
			.from('categories')
			.select('id, name_en, name_zh, slug, min_age_sum, max_teams, is_open, sort_order')
			.order('sort_order'),
		getTournamentConfig()
	]);

	return {
		categories: (categoryResult.data ?? []) as Category[],
		config
	};
};

export const actions: Actions = {
	register: async ({ request }) => {
		const formData = await request.formData();

		const p1FirstName = (formData.get('p1_firstName') as string)?.trim();
		const p1LastName = (formData.get('p1_lastName') as string)?.trim();
		const p1Gender = formData.get('p1_gender') as 'male' | 'female';
		const p1Dob = formData.get('p1_dob') as string;
		const p1Email = (formData.get('p1_email') as string)?.trim();
		const p1Phone = (formData.get('p1_phone') as string)?.trim() || null;
		const p1Wechat = (formData.get('p1_wechat') as string)?.trim() || null;

		const p2FirstName = (formData.get('p2_firstName') as string)?.trim();
		const p2LastName = (formData.get('p2_lastName') as string)?.trim();
		const p2Gender = formData.get('p2_gender') as 'male' | 'female';
		const p2Dob = formData.get('p2_dob') as string;
		const p2Email = (formData.get('p2_email') as string)?.trim();
		const p2Phone = (formData.get('p2_phone') as string)?.trim() || null;
		const p2Wechat = (formData.get('p2_wechat') as string)?.trim() || null;

		const categoryId = formData.get('category_id') as string;

		// Server-side validation
		if (!p1FirstName || !p1LastName || !p1Gender || !p1Dob || !p1Email) {
			return fail(400, { error: 'missing_player1_fields', success: false });
		}
		if (!p2FirstName || !p2LastName || !p2Gender || !p2Dob || !p2Email) {
			return fail(400, { error: 'missing_player2_fields', success: false });
		}
		if (!categoryId) {
			return fail(400, { error: 'missing_category', success: false });
		}

		const { data, error } = await supabase.rpc('register_team', {
			p1_name_en: `${p1FirstName} ${p1LastName}`,
			p1_email: p1Email,
			p1_gender: p1Gender,
			p1_dob: p1Dob,
			p1_phone: p1Phone,
			p1_wechat: p1Wechat,
			p2_name_en: `${p2FirstName} ${p2LastName}`,
			p2_email: p2Email,
			p2_gender: p2Gender,
			p2_dob: p2Dob,
			p2_phone: p2Phone,
			p2_wechat: p2Wechat,
			p_category_id: categoryId
		});

		if (error) {
			return fail(400, {
				error: parseRegistrationError(error.message),
				success: false
			});
		}

		return {
			success: true,
			teamId: data.team_id,
			status: data.status,
			genderType: data.gender_type,
			combinedAge: data.combined_age
		};
	}
};
