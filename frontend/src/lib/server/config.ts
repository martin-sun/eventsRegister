import { supabaseAdmin } from '$lib/server/supabase';
import type { TournamentConfig } from '$lib/types';

const DEFAULTS: TournamentConfig = {
	tournament_date: '2026-05-24T09:30:00-06:00',
	event_name: {
		en: 'The 2nd "L&T Realty Cup" Saskatoon Masters Badminton Championships',
		zh: '第二届「林与唐地产杯」萨斯卡通中老年羽毛球锦标赛'
	},
	venue: { en: 'Riverside Badminton & Tennis Club', zh: 'Riverside 羽毛球网球俱乐部' },
	venue_address: '645 Spadina Crescent W, Saskatoon, SK S7M 1C1',
	registration_fee: 30,
	min_age: 35,
	registration_open: true,
	registration_deadline: '2026-05-17T23:59:59-06:00',
	max_players: 128,
	etransfer_email: 'tournament@email.com',
	contact_phone: '(306) 555-1234',
	contact_wechat: 'saskatoon_badminton',
	payment_deadline_hours: 72
};

export async function getTournamentConfig(): Promise<TournamentConfig> {
	const { data, error } = await supabaseAdmin.from('tournament_config').select('key, value');

	if (error || !data) {
		return DEFAULTS;
	}

	const configMap: Record<string, unknown> = {};
	for (const row of data) {
		configMap[row.key] = row.value;
	}

	return {
		tournament_date: parseString(configMap.tournament_date, DEFAULTS.tournament_date),
		event_name: parseObject(configMap.event_name, DEFAULTS.event_name),
		venue: parseObject(configMap.venue, DEFAULTS.venue),
		venue_address: parseString(configMap.venue_address, DEFAULTS.venue_address),
		registration_fee: parseNumber(configMap.registration_fee, DEFAULTS.registration_fee),
		min_age: parseNumber(configMap.min_age, DEFAULTS.min_age),
		registration_open: parseBoolean(configMap.registration_open, DEFAULTS.registration_open),
		registration_deadline: parseString(
			configMap.registration_deadline,
			DEFAULTS.registration_deadline
		),
		max_players: parseNumber(configMap.max_players, DEFAULTS.max_players),
		etransfer_email: parseString(configMap.etransfer_email, DEFAULTS.etransfer_email),
		contact_phone: parseString(configMap.contact_phone, DEFAULTS.contact_phone),
		contact_wechat: parseString(configMap.contact_wechat, DEFAULTS.contact_wechat),
		payment_deadline_hours: parseNumber(
			configMap.payment_deadline_hours,
			DEFAULTS.payment_deadline_hours
		)
	};
}

function parseString(val: unknown, fallback: string): string {
	if (typeof val === 'string') return val;
	return fallback;
}

function parseNumber(val: unknown, fallback: number): number {
	if (typeof val === 'number') return val;
	if (typeof val === 'string') {
		const n = Number(val);
		if (!isNaN(n)) return n;
	}
	return fallback;
}

function parseBoolean(val: unknown, fallback: boolean): boolean {
	if (typeof val === 'boolean') return val;
	if (val === 'true') return true;
	if (val === 'false') return false;
	return fallback;
}

function parseObject<T>(val: unknown, fallback: T): T {
	if (typeof val === 'object' && val !== null) return val as T;
	return fallback;
}
