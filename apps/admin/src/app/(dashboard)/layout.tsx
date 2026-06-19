import Link from "next/link";
import { requireAdmin } from "@/lib/auth";
import { signOut } from "../login/actions";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await requireAdmin();

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          Bite<span>NYC</span>
        </div>
        <Link className="nav-link" href="/">
          Dashboard
        </Link>
        <Link className="nav-link" href="/restaurants">
          Restaurants
        </Link>
        <Link className="nav-link" href="/restaurants/new">
          Add restaurant
        </Link>
        <Link className="nav-link" href="/moderation">
          Moderation
        </Link>
        <div className="sidebar-footer">
          <div>{session.email}</div>
          <div className="muted">role: {session.role}</div>
          <form action={signOut} style={{ marginTop: 10 }}>
            <button className="btn" type="submit" style={{ width: "100%" }}>
              Sign out
            </button>
          </form>
        </div>
      </aside>
      <main className="content">{children}</main>
    </div>
  );
}
