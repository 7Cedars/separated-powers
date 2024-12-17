import { TwoSeventyRingWithBg } from "react-svg-spinners";

type ButtonProps = {
  statusButton?: 'pending' | 'success' | 'error' | 'disabled' | 'idle';
  showBorder?: boolean;
  selected?: boolean;
  size?: 0 | 1 | 2;   
  align?: 0 | 1 | 2;   
  role?: number; 
  children: any;
  onClick?: () => void;
};

const fontSize = [
  "text-sm h-6",
  "text-md p-2 h-12", 
  "text-lg p-3 h-16", 
]

const fontAlign = [
  "justify-left",
  "justify-center", 
  "justify-right", 
]

const roleColour = [
  "aria-selected:bg-blue-200 hover:border-blue-600",
  "aria-selected:bg-red-200 hover:border-red-600",
  "aria-selected:bg-amber-200 hover:border-amber-600",
  "aria-selected:bg-purple-200 hover:border-purple-600",
  "aria-selected:bg-green-200 hover:green-slate-600",
  "aria-selected:bg-orange-200 hover:border-orange-600",
  "aria-selected:bg-stone-200 hover:border-stone-600",
  "aria-selected:bg-slate-200 hover:border-slate-600"
]

export const Button = ({
  statusButton = 'idle', 
  showBorder = true,
  selected = false, 
  size = 1, 
  align = 1,
  role = 7,  
  onClick,
  children,
}: ButtonProps) => {

  return (
    <button 
      className={`w-full h-full disabled:opacity-50 rounded-md border ${roleColour[role]} ${fontSize[size]} ${showBorder ? "border-slate-300": "border-transparent"}`}  
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
