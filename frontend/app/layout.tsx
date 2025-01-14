import type { Metadata } from "next";
import localFont from "next/font/local";
import { ThemeProvider } from "@/context/Theme";
import { Providers } from "../context/Providers"
import { NavBars } from "../components/NavBars";
// import { Footer } from "../components/Footer";
import "./globals.css";

export const metadata: Metadata = {
  title: "Separated Powers",
  description: "AgDAO: an example implementation of a Separated Powers DAO",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className="h-dvh w-screen flex justify-center items-start relative bg-slate-100">
        <Providers>
          {/* <ThemeProvider> */}
            <NavBars > 
            {/* <div className="grow max-w-screen-lg max-h-screen h-fit grid grid-cols-1  py-20 px-2 overflow-y-auto"> */}
              {children}
            </NavBars > 
            {/* <Footer />  */}
          {/* </ThemeProvider> */}
        </Providers>
      </body>
    </html>
  );
}
