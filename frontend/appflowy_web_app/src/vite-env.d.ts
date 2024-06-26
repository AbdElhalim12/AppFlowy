/// <reference types="vite/client" />
/// <reference types="vite-plugin-svgr/client" />
/// <reference types="vite-plugin-terminal/client" />
/// <reference types="cypress" />
/// <reference types="cypress-plugin-tab" />

interface Window {
  refresh_token: (token: string) => void;
  invalid_token: () => void;
  WebFont?: {
    load: (options: { google: { families: string[] } }) => void;
  };
  toast: {
    success: (message: string) => void;
    error: (message: string) => void;
    info: (message: string) => void;
    clear: () => void;
    warning: (message: string) => void;
  };
}
