declare global {
  interface Window {
    __APP_CONFIG__?: {
      API_BASE_URL?: string;
      COGNITO_REGION?: string;
      COGNITO_USER_POOL_ID?: string;
      COGNITO_APP_CLIENT_ID?: string;
    };
  }
}

export {};
