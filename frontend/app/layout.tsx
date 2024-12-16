import type { Metadata } from "next";
import localFont from "next/font/local";
import { ThemeProvider } from "@/context/ThemeContext";
import { Providers } from "../context/Providers"
import { Header } from "../components/Header";
// import { Footer } from "../components/Footer";
import "./globals.css";

export const metadata: Metadata = {
  title: "Separated Powers",
  description: "AgDAO: an example implementation of a Separated Powers DAO",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className="h-dvh w-full flex justify-center items-center overflow-hidden relative bg-slate-100">
        <Providers>
          <ThemeProvider>
            <Header /> 
            <div className="grow max-w-screen-lg min-h-screen flex flex-col pt-20">
              {children}
            </div>
            {/* <Footer />  */}
          </ThemeProvider>
        </Providers>
      </body>
    </html>
  );
}
