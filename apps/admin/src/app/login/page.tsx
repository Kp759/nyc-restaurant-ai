"use client";

import { useFormState, useFormStatus } from "react-dom";
import { signIn, type LoginState } from "./actions";

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button className="btn btn-primary" type="submit" disabled={pending} style={{ width: "100%" }}>
      {pending ? "Signing in..." : "Sign in"}
    </button>
  );
}

export default function LoginPage() {
  const [state, formAction] = useFormState<LoginState, FormData>(signIn, {});

  return (
    <div className="login-wrap">
      <div className="brand" style={{ fontSize: 24, textAlign: "center" }}>
        Bite<span>NYC</span> Admin
      </div>
      <p className="muted" style={{ textAlign: "center", marginBottom: 20 }}>
        Curated NYC dining concierge
      </p>
      <form action={formAction} className="card">
        <div className="field">
          <label htmlFor="email">Email</label>
          <input id="email" name="email" type="email" autoComplete="email" required />
        </div>
        <div className="field">
          <label htmlFor="password">Password</label>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
          />
        </div>
        {state.error ? <p className="error">{state.error}</p> : null}
        <SubmitButton />
      </form>
      <p className="muted" style={{ fontSize: 12, textAlign: "center" }}>
        Access is limited to users in the admin_users table.
      </p>
    </div>
  );
}
