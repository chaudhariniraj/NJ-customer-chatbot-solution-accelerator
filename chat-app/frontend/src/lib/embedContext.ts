let embedAuthBaseUrl: string | null = null;

export function setEmbedAuthBaseUrl(url: string | null) {
  embedAuthBaseUrl = url ? url.replace(/\/$/, '') : null;
}

export function getEmbedAuthBaseUrl(): string | null {
  return embedAuthBaseUrl;
}
