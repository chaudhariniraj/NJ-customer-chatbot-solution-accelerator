/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string;
  readonly VITE_CHAT_WIDGET_ORIGIN?: string;
  readonly VITE_CHAT_API_BASE_URL?: string;
  readonly VITE_CHAT_WIDGET_THEME?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

interface Window {
  __RUNTIME_CONFIG__?: {
    VITE_API_BASE_URL?: string;
    VITE_CHAT_WIDGET_ORIGIN?: string;
    VITE_CHAT_API_BASE_URL?: string;
    VITE_CHAT_WIDGET_THEME?: string;
  };
  ChatWidget?: {
    init: (config: { apiBaseUrl: string; theme?: 'light' | 'dark'; scriptBaseUrl?: string }) => void;
  };
}
