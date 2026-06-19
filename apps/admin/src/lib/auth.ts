import "server-only";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "./supabase/server";
import { createServiceClient } from "./supabase/service";

export interface AdminSession {
  userId: string;
  email: string;
  role: "admin" | "editor";
}

/** Returns the current admin session, or null if not signed in / not allowed. */
export async function getAdminSession(): Promise<AdminSession | null> {
  const supabase = createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user?.email) return null;

  const service = createServiceClient();
  const { data: adminRow } = await service
    .from("admin_users")
    .select("role")
    .eq("email", user.email.toLowerCase())
    .maybeSingle();

  if (!adminRow) return null;
  return { userId: user.id, email: user.email, role: adminRow.role };
}

/** Guard for protected pages/actions. Redirects to /login when unauthorized. */
export async function requireAdmin(): Promise<AdminSession> {
  const session = await getAdminSession();
  if (!session) redirect("/login");
  return session;
}
