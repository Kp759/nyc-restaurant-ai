import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { adminEnv } from "../env";

/** Auth-aware Supabase client bound to the request cookies (anon key). */
export function createSupabaseServerClient() {
  const cookieStore = cookies();
  return createServerClient(adminEnv.supabaseUrl, adminEnv.supabaseAnonKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet: Array<{ name: string; value: string; options?: any }>) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options),
          );
        } catch {
          // Called from a Server Component where cookies are read-only.
          // Session refresh is handled in middleware, so this is safe to ignore.
        }
      },
    },
  });
}
