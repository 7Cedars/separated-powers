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
  document.documentElement.requestFullscreen();

  return (
    <html lang="en">
      <body className="h-dvh w-screen flex flex-col justify-start items-start relative bg-slate-100 border border-green-500">
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
