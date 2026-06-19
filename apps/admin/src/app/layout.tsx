import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "BiteNYC Admin",
  description: "Curate NYC restaurants, dishes, media, and moderation for BiteNYC.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
