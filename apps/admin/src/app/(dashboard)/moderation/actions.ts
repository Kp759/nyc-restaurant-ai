"use server";

import { revalidatePath } from "next/cache";
import { requireAdmin } from "@/lib/auth";
import { createServiceClient } from "@/lib/supabase/service";

type Resolution = "resolved" | "dismissed";

export async function resolveReport(id: string, status: Resolution) {
  const session = await requireAdmin();
  const service = createServiceClient();
  const { error } = await service
    .from("content_reports")
    .update({ status, resolved_by: session.email, resolved_at: new Date().toISOString() })
    .eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/moderation");
}

export async function resolveTakedown(id: string, status: Resolution) {
  const session = await requireAdmin();
  const service = createServiceClient();
  const { error } = await service
    .from("takedown_requests")
    .update({ status, resolved_by: session.email, resolved_at: new Date().toISOString() })
    .eq("id", id);
  if (error) throw new Error(error.message);
  revalidatePath("/moderation");
}
