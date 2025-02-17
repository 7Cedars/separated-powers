/** @type {import('next').NextConfig} */
const nextConfig = {
  contentSecurityPolicy: "default-src 'self'; script-src 'none'; sandbox;",
};

export default nextConfig;