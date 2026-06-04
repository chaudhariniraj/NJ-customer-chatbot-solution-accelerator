const EASYAUTH_LOGIN_PATH = '/.auth/login/aad';
const REDIRECT_GUARD_KEY = 'easyauth_redirect_in_progress';

const AUTH_HOST_HINTS = [
  'login.windows.net',
  'login.microsoftonline.com',
  '/.auth/login/',
];

export const buildEasyAuthLoginUrl = (returnUrl?: string): string => {
  if (typeof window === 'undefined') {
    return EASYAUTH_LOGIN_PATH;
  }

  const targetReturnUrl = returnUrl || window.location.href;
  return `${EASYAUTH_LOGIN_PATH}?post_login_redirect_uri=${encodeURIComponent(targetReturnUrl)}`;
};

export const isAuthRedirectUrl = (url?: string): boolean => {
  if (!url) {
    return false;
  }

  return AUTH_HOST_HINTS.some((hint) => url.includes(hint));
};

export const shouldTriggerEasyAuthRedirect = (status?: number, responseUrl?: string): boolean => {
  return status === 401 || status === 403 || status === 302 || isAuthRedirectUrl(responseUrl);
};

export const redirectToEasyAuthLogin = (returnUrl?: string): void => {
  if (typeof window === 'undefined') {
    return;
  }

  if (sessionStorage.getItem(REDIRECT_GUARD_KEY) === '1') {
    return;
  }

  const loginUrl = buildEasyAuthLoginUrl(returnUrl);
  sessionStorage.setItem(REDIRECT_GUARD_KEY, '1');

  try {
    if (window.top && window.top !== window.self) {
      window.top.location.assign(loginUrl);
      return;
    }
  } catch {
    // Ignore cross-frame access errors and fall back to current window.
  }

  window.location.assign(loginUrl);
};

export const clearEasyAuthRedirectGuard = (): void => {
  if (typeof window === 'undefined') {
    return;
  }

  sessionStorage.removeItem(REDIRECT_GUARD_KEY);
};