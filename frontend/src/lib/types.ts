// Types matching Supabase table/view/function return shapes

export interface CategoryStat {
	id: string;
	name_en: string;
	name_zh: string;
	slug: string;
	max_teams: number;
	is_open: boolean;
	registered_teams: number;
	remaining_slots: number;
}

export interface Sponsor {
	id: string;
	name_zh: string;
	name_en: string;
	level: 'title' | 'diamond' | 'platinum' | 'gold' | 'friend' | 'media';
	logo_url: string | null;
	website: string | null;
	description_zh: string | null;
	description_en: string | null;
	sort_order: number;
}

export interface PublicTeam {
	team_id: string;
	category_slug: string;
	category_zh: string;
	category_en: string;
	gender_type: 'mens' | 'womens' | 'mixed';
	combined_age: number;
	player1_display_name: string;
	player2_display_name: string;
	status: 'pending' | 'confirmed' | 'waitlist' | 'cancelled';
	seed: number | null;
	created_at: string;
}

export interface Category {
	id: string;
	name_en: string;
	name_zh: string;
	slug: string;
	min_age_sum: number;
	max_teams: number;
	is_open: boolean;
	sort_order: number;
}

export interface TournamentConfig {
	tournament_date: string;
	event_name: { en: string; zh: string };
	venue: { en: string; zh: string };
	venue_address: string;
	registration_fee: number;
	min_age: number;
	registration_open: boolean;
	registration_deadline: string;
	max_players: number;
	etransfer_email: string;
	contact_phone: string;
	contact_wechat: string;
	payment_deadline_hours: number;
}

export interface AdminTeam {
	team_id: string;
	team_name_zh: string | null;
	team_name_en: string | null;
	gender_type: 'mens' | 'womens' | 'mixed';
	combined_age: number;
	status: 'pending' | 'confirmed' | 'waitlist' | 'cancelled';
	payment_status: 'unpaid' | 'paid' | 'refunded';
	paid_at: string | null;
	payment_notes: string | null;
	payment_ref: string;
	confirmation_email_sent_at: string | null;
	seed: number | null;
	created_at: string;
	category_en: string;
	category_zh: string;
	category_slug: string;
	player1_id: string;
	player1_name_en: string;
	player1_name_zh: string | null;
	player1_gender: string;
	player1_email: string;
	player1_phone: string | null;
	player1_wechat: string | null;
	player1_age: number;
	player2_id: string;
	player2_name_en: string;
	player2_name_zh: string | null;
	player2_gender: string;
	player2_email: string;
	player2_phone: string | null;
	player2_wechat: string | null;
	player2_age: number;
}

export interface DashboardStats {
	total_teams: number;
	confirmed_teams: number;
	pending_teams: number;
	waitlist_teams: number;
	cancelled_teams: number;
	paid_teams: number;
	unpaid_teams: number;
	total_revenue: number;
	expected_revenue: number;
}
