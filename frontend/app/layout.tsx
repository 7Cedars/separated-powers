import type { Metadata } from "next";
import localFont from "next/font/local";
import { ThemeProvider } from "@/context/ThemeContext";
import { Providers } from "../context/Providers"
import "./globals.css";

export const metadata: Metadata = {
  title: "Separated Powers",
  description: "AgDAO: an example implementation of a Separated Powers DAO",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>
        <Providers>
          <ThemeProvider>
            {children}
          </ThemeProvider>
        </Providers>
      </body>
    </html>
  );
}
