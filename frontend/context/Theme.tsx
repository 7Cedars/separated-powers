// ThemeContext.tsx
// added local theming as well. 

'use client';

import React, {
    createContext,
    useState,
    ReactNode,
    useContext,
    useEffect,
    SetStateAction,
    Dispatch
} from 'react';

const roleColour = [  
    "border-blue-600", 
    "border-red-600", 
    "border-yellow-600", 
    "border-purple-600",
    "border-green-600", 
    "border-orange-600", 
    "border-slate-600"
  ]

const colourScheme = [
    "from-indigo-500 to-emerald-500", 
    "from-blue-500 to-red-500", 
    "from-indigo-300 to-emerald-900",
    "from-emerald-400 to-indigo-700 ",
    "from-red-200 to-blue-400",
    "from-red-800 to-blue-400"
]

interface ThemeContextProps {
    theme: string;
    setTheme: Dispatch<SetStateAction<string>>;
}

const ThemeContext = createContext<ThemeContextProps>({
    theme: 'dark',
    setTheme: () => { }
});

const ThemeProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [theme, setTheme] = useState<string>('light');

    useEffect(() => {
        const savedTheme = localStorage.getItem('theme') || 'dark';
        setTheme(savedTheme);
    }, []);

    useEffect(() => {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
    }, [theme]);


    return (
        <ThemeContext.Provider value={{
            theme,
            setTheme
        }}>
            {children}
        </ThemeContext.Provider>
    );
};

const useTheme = () => {
    const context = useContext(ThemeContext);
    if (!context) {
        throw new Error('useTheme must be used within a ThemeProvider');
    }
    return context;
};

export { roleColour, colourScheme, ThemeProvider, useTheme };
