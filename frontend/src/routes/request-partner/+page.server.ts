import type { PageServerLoad, Actions } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import { getTournamentConfig } from '$lib/server/config';
import { sendPartnerRequestEmail } from '$lib/server/email';
import { fail } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
import type { Category } from '$lib/types';

export const load: PageServerLoad = async () => {
	const categoryResult = await supabaseAdmin
		.from('categories')
		.select('id, name_en, name_zh, slug, min_age_sum, max_teams, is_open, sort_order')
		.order('sort_order');

	return {
		categories: (categoryResult.data ?? []) as Category[]
	};
};

export const actions: Actions = {
	submit: async ({ request, url }) => {
		const formData = await request.formData();

		const firstName = (formData.get('firstName') as string)?.trim();
		const lastName = (formData.get('lastName') as string)?.trim();
		const gender = formData.get('gender') as string;
		const dob = formData.get('dob') as string;
		const email = (formData.get('email') as string)?.trim();
		const phone = (formData.get('phone') as string)?.trim() || '';
		const wechat = (formData.get('wechat') as string)?.trim() || '';
		const preferredCategory = (formData.get('preferredCategory') as string)?.trim() || '';
		const notes = (formData.get('notes') as string)?.trim() || '';
		const locale = (formData.get('locale') as string) || 'en';

		// Validate required fields
		if (!firstName || !lastName || !gender || !dob || !email) {
			return fail(400, { error: 'missing_fields' });
		}

		if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
			return fail(400, { error: 'email_invalid' });
		}

		// Calculate age
		const tournamentDate = new Date('2026-05-24T09:30:00-06:00');
		const birth = new Date(dob);
		let age = tournamentDate.getFullYear() - birth.getFullYear();
		const monthDiff = tournamentDate.getMonth() - birth.getMonth();
		if (monthDiff < 0 || (monthDiff === 0 && tournamentDate.getDate() < birth.getDate())) {
			age--;
		}

		// Send email to organizer
		const config = await getTournamentConfig();
		const resendFrom = env.RESEND_FROM || 'tournament@resend.dev';
		const siteUrl = `${url.protocol}//${url.host}`;

		if (env.RESEND_API_KEY) {
			try {
				await sendPartnerRequestEmail(env.RESEND_API_KEY, resendFrom, {
					firstName,
					lastName,
					gender,
					dob,
					age,
					email,
					phone,
					wechat,
					preferredCategory,
					notes,
					config,
					locale,
					siteUrl
				});
			} catch (err) {
				console.error('[request-partner] Failed to send email:', err);
				return fail(500, { error: 'send_failed' });
			}
		} else {
			console.log('[request-partner] No RESEND_API_KEY, skipping email. Data:', {
				firstName, lastName, gender, dob, age, email, phone, wechat, preferredCategory, notes
			});
		}

		return { success: true };
	}
};
