/**
 * Creates (or authorizes) a BiteNYC admin user: provisions a Supabase auth user
 * and adds the email to the admin_users allowlist used by the admin CMS.
 *
 * Usage:
 *   pnpm --filter @bitenyc/scripts create:admin -- <email> <password> [admin|editor]
 */
import { getServiceClient } from "./lib/env.js";

async function main() {
  const [email, password, role = "admin"] = process.argv.slice(2);
  if (!email || !password) {
    console.error("Usage: create:admin -- <email> <password> [admin|editor]");
    process.exit(1);
  }
  if (role !== "admin" && role !== "editor") {
    console.error("Role must be 'admin' or 'editor'.");
    process.exit(1);
  }

  const supabase = getServiceClient();
  const normalized = email.toLowerCase();

  const { data: created, error: createErr } = await supabase.auth.admin.createUser({
    email: normalized,
    password,
    email_confirm: true,
  });
  if (createErr && !/already.*registered|exists/i.test(createErr.message)) {
    throw createErr;
  }
  if (created?.user) {
    console.log(`Auth user ready: ${normalized}`);
  } else {
    console.log(`Auth user already existed: ${normalized}`);
  }

  const { error: upsertErr } = await supabase
    .from("admin_users")
    .upsert({ email: normalized, role }, { onConflict: "email" });
  if (upsertErr) throw upsertErr;

  console.log(`Authorized ${normalized} as ${role}.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
