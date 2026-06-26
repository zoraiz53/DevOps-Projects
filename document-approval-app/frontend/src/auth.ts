import {
  CognitoIdentityProviderClient,
  InitiateAuthCommand,
} from "@aws-sdk/client-cognito-identity-provider";

export type AppRole = "manager" | "employee";

export type AuthSession = {
  accessToken: string;
  idToken: string;
  refreshToken?: string;
  username: string;
  email?: string;
  name: string;
  groups: AppRole[];
};

type JwtPayload = {
  "cognito:groups"?: string[];
  "cognito:username"?: string;
  email?: string;
  name?: string;
  sub?: string;
};

const COGNITO_REGION = window.__APP_CONFIG__?.COGNITO_REGION ?? "";
const COGNITO_APP_CLIENT_ID = window.__APP_CONFIG__?.COGNITO_APP_CLIENT_ID ?? "";
const STORAGE_KEY = "document-approval-auth";

const client = new CognitoIdentityProviderClient({
  region: COGNITO_REGION || "us-east-1",
});

function decodeJwt<T>(token: string): T {
  const payload = token.split(".")[1];
  if (!payload) {
    throw new Error("Invalid JWT payload.");
  }

  const normalized = payload.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4 || 4)) % 4);
  return JSON.parse(window.atob(padded)) as T;
}

function toSession(accessToken: string, idToken: string, refreshToken?: string): AuthSession {
  const accessPayload = decodeJwt<JwtPayload>(accessToken);
  const idPayload = decodeJwt<JwtPayload>(idToken);
  const groups = (accessPayload["cognito:groups"] ?? idPayload["cognito:groups"] ?? [])
    .map((group) => group.toLowerCase())
    .filter((group): group is AppRole => group === "manager" || group === "employee");
  const username =
    idPayload["cognito:username"] ?? accessPayload["cognito:username"] ?? idPayload.sub ?? "user";

  return {
    accessToken,
    idToken,
    refreshToken,
    username,
    email: idPayload.email,
    name: idPayload.name ?? idPayload.email ?? username,
    groups,
  };
}

function ensureConfig() {
  if (!COGNITO_REGION || !COGNITO_APP_CLIENT_ID) {
    throw new Error("Missing Cognito frontend configuration.");
  }
}

export function getStoredSession(): AuthSession | null {
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as AuthSession;
  } catch {
    window.localStorage.removeItem(STORAGE_KEY);
    return null;
  }
}

export function storeSession(session: AuthSession | null) {
  if (!session) {
    window.localStorage.removeItem(STORAGE_KEY);
    return;
  }
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
}

export async function login(email: string, password: string) {
  ensureConfig();
  const response = await client.send(
    new InitiateAuthCommand({
      AuthFlow: "USER_PASSWORD_AUTH",
      ClientId: COGNITO_APP_CLIENT_ID,
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password,
      },
    }),
  );

  const result = response.AuthenticationResult;
  if (!result?.AccessToken || !result.IdToken) {
    throw new Error("Cognito login did not return tokens.");
  }

  const session = toSession(result.AccessToken, result.IdToken, result.RefreshToken);
  storeSession(session);
  return session;
}

export function logout() {
  storeSession(null);
}
