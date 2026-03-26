/**
 * Maps Supabase trigger error messages to i18n error keys.
 * The trigger exceptions from migration 003 have specific message patterns.
 */
export function parseRegistrationError(message: string): string {
	if (message.includes('Combined age')) return 'combined_age_insufficient';
	if (message.includes('at least 35')) return 'individual_age_insufficient';
	if (message.includes('already registered')) return 'player_already_registered';
	if (message.includes('Registration is closed')) return 'registration_closed';
	if (message.includes('Please wait')) return 'rate_limited';
	if (message.includes('team_different_players')) return 'same_player';
	if (message.includes('duplicate key') || message.includes('email')) return 'email_conflict';
	return 'unknown_error';
}
