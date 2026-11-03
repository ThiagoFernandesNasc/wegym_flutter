import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const routeMocks = vi.hoisted(() => ({
  authenticate: vi.fn(),
  withRateLimit: vi.fn(),
  stravaAuthorizationUrl: vi.fn(),
  googleFitAuthorizationUrl: vi.fn(),
  stravaExchangeCode: vi.fn(),
  googleFitExchangeCode: vi.fn(),
  saveTokens: vi.fn(),
}));

vi.mock("@/lib/api-utils", () => ({
  authenticate: routeMocks.authenticate,
  handleError: (error: unknown) =>
    Response.json({ error: String(error) }, { status: 500 }),
  json: (data: unknown, status = 200) => Response.json(data, { status }),
  withRateLimit: routeMocks.withRateLimit,
}));
vi.mock("@/lib/services/integration.service", () => ({
  integrationService: {
    getIntegrations: vi.fn(),
    disconnect: vi.fn(),
    saveTokens: routeMocks.saveTokens,
  },
}));
vi.mock("@/lib/services/strava.service", () => ({
  stravaService: {
    getAuthorizationUrl: routeMocks.stravaAuthorizationUrl,
    exchangeCode: routeMocks.stravaExchangeCode,
  },
}));
vi.mock("@/lib/services/google-fit.service", () => ({
  googleFitService: {
    getAuthorizationUrl: routeMocks.googleFitAuthorizationUrl,
    exchangeCode: routeMocks.googleFitExchangeCode,
  },
}));

import { POST } from "@/app/api/integrations/route";
import { GET as stravaCallback } from "@/app/api/integrations/strava/callback/route";
import { GET as googleFitCallback } from "@/app/api/integrations/google-fit/callback/route";
import {
  createIntegrationOAuthState,
  verifyIntegrationOAuthState,
} from "@/lib/integration-oauth-state";

describe("OAuth integration routes", () => {
  afterEach(() => vi.unstubAllEnvs());

  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("NEXTAUTH_SECRET", "route-test-secret");
    routeMocks.authenticate.mockResolvedValue({ user: { id: "athlete-1" } });
    routeMocks.withRateLimit.mockResolvedValue(null);
    routeMocks.stravaExchangeCode.mockResolvedValue({
      accessToken: "strava-access-token",
    });
    routeMocks.googleFitExchangeCode.mockResolvedValue({
      accessToken: "google-access-token",
    });
    routeMocks.saveTokens.mockResolvedValue(undefined);
    routeMocks.stravaAuthorizationUrl.mockImplementation(
      (state: string) =>
        `https://www.strava.com/oauth/authorize?state=${encodeURIComponent(state)}`,
    );
    routeMocks.googleFitAuthorizationUrl.mockImplementation(
      (state: string) =>
        `https://accounts.google.com/o/oauth2/v2/auth?state=${encodeURIComponent(state)}`,
    );
  });

  it.each(["flutter_web", "flutter_native", "next"] as const)(
    "signs the requested %s platform into OAuth state",
    async (platform) => {
      const response = await POST(
        new Request("http://localhost:3000/api/integrations", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ provider: "strava", platform }),
        }),
      );
      const result = (await response.json()) as { url: string };
      const state = new URL(result.url).searchParams.get("state");

      expect(response.status).toBe(200);
      expect(
        verifyIntegrationOAuthState(state, "strava", "route-test-secret"),
      ).toEqual({
        userId: "athlete-1",
        provider: "strava",
        platform,
      });
    },
  );

  it("saves Strava tokens for the signed-in account then redirects to the native app", async () => {
    vi.stubEnv("FLUTTER_NATIVE_APP_URL", "");
    const state = createIntegrationOAuthState(
      {
        userId: "athlete-1",
        provider: "strava",
        platform: "flutter_native",
      },
      "route-test-secret",
    );
    const response = await stravaCallback(
      new Request(
        `https://api.wegym.example/api/integrations/strava/callback?code=auth-code&state=${encodeURIComponent(state)}`,
      ),
    );
    const location = new URL(response.headers.get("location")!);

    expect(response.status).toBe(302);
    expect(routeMocks.stravaExchangeCode).toHaveBeenCalledWith("auth-code");
    expect(routeMocks.saveTokens).toHaveBeenCalledWith("athlete-1", "strava", {
      accessToken: "strava-access-token",
    });
    expect(location.protocol).toBe("wegym:");
    expect(location.host).toBe("integration-return");
    expect(location.searchParams.get("integration_result")).toBe("success");
  });

  it("saves Google Fit tokens and returns web users to the configured Flutter origin", async () => {
    vi.stubEnv("FLUTTER_APP_URL", "https://app.wegym.example");
    const state = createIntegrationOAuthState(
      {
        userId: "athlete-2",
        provider: "google_fit",
        platform: "flutter_web",
      },
      "route-test-secret",
    );
    const response = await googleFitCallback(
      new Request(
        `https://api.wegym.example/api/integrations/google-fit/callback?code=auth-code&state=${encodeURIComponent(state)}`,
      ),
    );
    const location = new URL(response.headers.get("location")!);

    expect(response.status).toBe(302);
    expect(routeMocks.googleFitExchangeCode).toHaveBeenCalledWith("auth-code");
    expect(routeMocks.saveTokens).toHaveBeenCalledWith(
      "athlete-2",
      "google_fit",
      {
        accessToken: "google-access-token",
      },
    );
    expect(location.origin).toBe("https://app.wegym.example");
    expect(location.searchParams.get("integration")).toBe("google_fit");
    expect(location.searchParams.get("integration_result")).toBe("success");
  });
});
