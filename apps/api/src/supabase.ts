import { createClient } from "@supabase/supabase-js";
import { env } from "./env.js";

/**
 * Server-side Supabase client using the service role key. This bypasses RLS,
 * so it must NEVER be exposed to the browser. All public read endpoints in this
 * API explicitly filter to status = 'published'.
 */
export const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
