import type { LayoutServerLoad } from './$types';
import { redirect } from '@sveltejs/kit';
import { supabaseAdmin } from '$lib/server/supabase';

export const load: LayoutServerLoad = async ({ cookies, url }) => {
	// Login page is accessible without auth
	if (url.pathname === '/admin/login') {
		return { user: null };
	}

	const token = cookies.get('admin-session');
	if (!token) {
		throw redirect(303, '/admin/login');
	}

	const {
		data: { user },
		error
	} = await supabaseAdmin.auth.getUser(token);

	if (error || !user || user.app_metadata?.role !== 'admin') {
		cookies.delete('admin-session', { path: '/admin' });
		throw redirect(303, '/admin/login');
	}

	return { user: { email: user.email ?? '' } };
};
