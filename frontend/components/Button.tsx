"use client"

import { TwoSeventyRingWithBg } from "react-svg-spinners";

type ButtonProps = {
  statusButton?: 'pending' | 'success' | 'error' | 'disabled' | 'idle';
  showBorder?: boolean;
  selected?: boolean;
  size?: 0 | 1 | 2;   
  align?: 0 | 1 | 2;   
  role?: number; 
  children: any;
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
};

const fontSize = [
  "text-sm h-6",
  "text-md p-1 h-10", 
  "text-lg p-3 h-16", 
]

const fontAlign = [
  "justify-left text-left",
  "justify-center text-center", 
  "justify-right text-right", 
]

const roleBorderColour = [
  "aria-selected:bg-blue-200 hover:border-blue-600 border-blue-600",
  "aria-selected:bg-red-200 hover:border-red-600 border-red-600",
  "aria-selected:bg-yellow-200 hover:border-yellow-600 border-yellow-600",
  "aria-selected:bg-purple-200 md:hover:border-purple-600 border-purple-600",
  "aria-selected:bg-green-200 md:hover:green-600 border-green-600",
  "aria-selected:bg-orange-200 md:hover:border-orange-600 border-orange-600",
  "aria-selected:bg-slate-200 md:hover:border-slate-600 border-slate-400"
]

export const Button = ({
  statusButton = 'idle', 
  showBorder = true,
  selected = false, 
  size = 1, 
  align = 1,
  role = 6,  
  onClick,
  children,
}: ButtonProps) => {

  return (
    <button 
      className={`w-full h-full disabled:opacity-50 rounded-md border ${roleBorderColour[role % roleBorderColour.length]} ${fontSize[size]} ${showBorder ? "border-slate-300": "md:border-transparent"}`}  
      onClick={onClick} 
      disabled={statusButton != 'idle'}
      aria-selected={selected}
      >
        <div className={`flex flex-row items-center ${fontAlign[align]} text-slate-600 gap-1 w-full h-full w-full px-2 py-1`}>
        {
          statusButton == 'pending' ?  
          <>
          <div> 
            <TwoSeventyRingWithBg />
            </div>
            <div>
              Loading...
              </div>
            </>
          : 
          statusButton == 'success' ? 
            <>
            Success! 
            </>
          :
          statusButton == 'error' ? 
            <>
            Error 
            </>
          :
          <>
            {children}
          </>
        }
      </div>
    </button>
  );
};
