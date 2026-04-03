import type { PageServerLoad, Actions } from './$types';
import { supabaseAdmin } from '$lib/server/supabase';
import { getTournamentConfig } from '$lib/server/config';
import { sendRegistrationEmail } from '$lib/server/email';
import { fail } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';
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

export const actions: Actions = {
	resend_email: async ({ request, url }) => {
		const formData = await request.formData();
		const teamId = formData.get('team_id') as string;
		const locale = (formData.get('locale') as string) || 'en';

		if (!teamId) {
			return fail(400, { error: 'Missing team_id' });
		}

		// Fetch team details
		const { data: team, error: teamError } = await supabaseAdmin
			.from('teams_detail')
			.select('*')
			.eq('team_id', teamId)
			.single();

		if (teamError || !team) {
			return fail(404, { error: 'Team not found' });
		}

		const config = await getTournamentConfig();
		const resendFrom = env.RESEND_FROM || 'tournament@resend.dev';

		if (!env.RESEND_API_KEY) {
			return fail(500, { error: 'Email service not configured' });
		}

		const categoryName = locale === 'zh' ? team.category_zh : team.category_en;

		try {
			await sendRegistrationEmail(env.RESEND_API_KEY, resendFrom, {
				to: team.player1_email,
				player1Name: team.player1_name_en,
				player2Name: team.player2_name_en,
				player1Email: team.player1_email,
				player2Email: team.player2_email,
				categoryName,
				genderType: team.gender_type,
				combinedAge: team.combined_age,
				teamId: team.team_id,
				status: team.status,
				config,
				locale,
				siteUrl: url.origin
			});

			// Mark email as sent via direct update (service-role bypasses RLS)
			const { error: markError } = await supabaseAdmin
				.from('teams')
				.update({ confirmation_email_sent_at: new Date().toISOString() })
				.eq('id', teamId);
			if (markError) {
				console.error('[admin resend_email] Failed to mark email sent:', markError.message);
			}

			return { success: true };
		} catch (err) {
			console.error('[admin resend_email] Error:', err);
			return fail(500, { error: 'Failed to send email' });
		}
	}
};
