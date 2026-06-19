/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ["@bitenyc/shared"],
  eslint: { ignoreDuringBuilds: true },
};

export default nextConfig;
