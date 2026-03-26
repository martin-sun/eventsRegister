import type { LayoutServerLoad } from './$types';
import { redirect } from '@sveltejs/kit';

export const load: LayoutServerLoad = async ({ url }) => {
	// Login page is accessible without auth
	if (url.pathname === '/admin/login') {
		return {};
	}

	// Auth check happens client-side via supabaseAuth.
	// Server-side we just pass through — the client layout handles redirect.
	return {};
};
