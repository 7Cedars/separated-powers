import type { Metadata } from "next";
import localFont from "next/font/local";
import { ThemeProvider } from "@/context/Theme";
import { Providers } from "../context/Providers"
import { NavBars } from "../components/NavBars";
import "./globals.css";

export const metadata: Metadata = {
  title: "Powers Protocol",
  description: "UI to interact with organisations using the Powers Protocol.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      {/* h-dvh */}
      <body className="h-screen w-screen flex flex-col justify-start items-start relative bg-slate-100 overflow-hidden">
        <Providers>
          {/* <ThemeProvider> */}
            <NavBars > 
              {children}
            </NavBars > 
          {/* </ThemeProvider> */}
        </Providers>
      </body>
    </html>
  );
}
