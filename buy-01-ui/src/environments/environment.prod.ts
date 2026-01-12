// src/environments/environment.prod.ts
// This is the PRODUCTION file for Docker builds
export const environment = {
  production: true,
  // Use HTTPS for both frontend and API Gateway
  apiUrl: `https://${window.location.hostname}:8443/api`,
  apiGatewayUrl: `https://${window.location.hostname}:8443`,
  authUrl: `https://${window.location.hostname}:8443/api/auth`,
  usersUrl: `https://${window.location.hostname}:8443/api/users`,
  productsUrl: `https://${window.location.hostname}:8443/api/products`,
  mediaUrl: `https://${window.location.hostname}:8443/api/media`,
  enableDebugLogging: false,
  buildTimestamp: '2026-01-08T13:00:00Z',
};
