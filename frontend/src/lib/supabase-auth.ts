import { createClient } from '@supabase/supabase-js';
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

/**
 * Separate Supabase client for auth operations.
 * The main client uses schema 'events_register', but auth requires the default 'public' schema.
 */
export const supabaseAuth = createClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY);
