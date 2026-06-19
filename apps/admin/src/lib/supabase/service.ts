import "server-only";
import { createClient } from "@supabase/supabase-js";
import { adminEnv } from "../env";

/**
 * Service-role Supabase client for all admin data operations (reads/writes of
 * draft + published content). Server-only: never import into a client component.
 */
export function createServiceClient() {
  return createClient(adminEnv.supabaseUrl, adminEnv.supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
