import { TwoSeventyRingWithBg } from "react-svg-spinners";

type ButtonProps = {
  statusButton?: 'pending' | 'success' | 'error' | 'disabled' | 'idle';
  showBorder?: boolean;
  selected?: boolean;
  size?: 0 | 1 | 2;   
  align?: 0 | 1 | 2;   
  children: any;
  onClick?: () => void;
};

const fontSize = [
  "text-xs h-6",
  "text-md p-2 h-12", 
  "text-lg p-3 h-16", 
]

const fontAlign = [
  "justify-left",
  "justify-center", 
  "justify-right", 
]

export const Button = ({
  statusButton = 'idle', 
  showBorder = true,
  selected = false, 
  size = 1, 
  align = 1, 
  onClick,
  children,
}: ButtonProps) => {

  return (
    <button 
      className={`w-full h-full disabled:opacity-50 aria-selected:bg-slate-200 hover:border-slate-600 rounded-md ${fontSize[size]} ${fontAlign[align]} ${showBorder ? "border border-slate-300": "border border-transparent"}`}  
      onClick={onClick} 
      disabled={statusButton != 'idle'}
      aria-selected={selected}
      >
        <div className={`flex flex-row items-center ${fontAlign[align]} gap-1 w-full h-full w-full px-2 py-1`}>
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
