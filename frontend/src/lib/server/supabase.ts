import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL } from '$env/static/public';
import { SUPABASE_SERVICE_ROLE_KEY } from '$env/static/private';

/**
 * Server-side Supabase client using service role key.
 * Bypasses RLS — use only in +page.server.ts / +layout.server.ts / server hooks.
 * NEVER import this from client-side code.
 */
export const supabaseAdmin = createClient(PUBLIC_SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
	db: { schema: 'events_register' },
	auth: { autoRefreshToken: false, persistSession: false }
});
