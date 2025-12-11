package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

func TestValidateSecrets(t *testing.T) {
	longSecret := "this-is-an-extremely-long-secret-key-with-many-characters-to-" + // pragma: allowlist secret
		"ensure-maximum-security-12345678901234567890"

	tests := []struct {
		name        string
		secret      string
		shouldError bool
		setupEnv    func()
		cleanup     func()
	}{
		{
			name:        "Valid secret with sufficient length",
			secret:      "this-is-a-sufficiently-long-secret-key-12345678",
			shouldError: false,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "this-is-a-sufficiently-long-secret-key-12345678")
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
		{
			name:        "Secret exactly 32 characters (boundary test)",
			secret:      "12345678901234567890123456789012",
			shouldError: false,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "12345678901234567890123456789012")
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
		{
			name:        "Secret with 31 characters (just below minimum)",
			secret:      "1234567890123456789012345678901",
			shouldError: true,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "1234567890123456789012345678901")
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
		{
			name:        "Empty secret",
			secret:      "",
			shouldError: true,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "")
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
		{
			name:        "Missing environment variable",
			secret:      "",
			shouldError: true,
			setupEnv: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
			cleanup: func() {
				// Nothing to cleanup
			},
		},
		{
			name:        "Very long secret (should be valid)",
			secret:      longSecret,
			shouldError: false,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", longSecret)
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
		{
			name:        "Secret with special characters",
			secret:      "my-$ecret!@#key%^&*()_+-=[]{}|;:',.<>?/~`",
			shouldError: false,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "my-$ecret!@#key%^&*()_+-=[]{}|;:',.<>?/~`")
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
		{
			name:        "Secret with whitespace (still counts toward length)",
			secret:      "secret with spaces that is long enough for validation",
			shouldError: false,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "secret with spaces that is long enough for validation")
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
		{
			name:        "Secret with only whitespace",
			secret:      "                                ",
			shouldError: true, // Whitespace-only secrets are now rejected
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "                                ")
			},
			cleanup: func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Setup
			tt.setupEnv()
			defer tt.cleanup()

			// Execute
			err := validateSecrets()

			// Assert
			if tt.shouldError && err == nil {
				t.Errorf("validateSecrets() expected error but got none")
			}
			if !tt.shouldError && err != nil {
				t.Errorf("validateSecrets() unexpected error: %v", err)
			}

			// Additional validation: check error message content
			if err != nil {
				errMsg := err.Error()
				if tt.secret == "" && os.Getenv("WEBUI_SECRET_KEY") == "" {
					if errMsg != "CRITICAL: WEBUI_SECRET_KEY environment variable not set" {
						t.Errorf("Expected 'not set' error message, got: %s", errMsg)
					}
				} else if tt.secret != "" && len(tt.secret) < 32 {
					expectedSubstring := "too short"
					if !strings.Contains(errMsg, expectedSubstring) {
						t.Errorf("Expected error message to contain '%s', got: %s", expectedSubstring, errMsg)
					}
				}
			}
		})
	}
}

func TestValidateSecretsIntegration(t *testing.T) {
	// Save original env var if it exists
	originalSecret := os.Getenv("WEBUI_SECRET_KEY")
	defer func() {
		if originalSecret != "" {
			os.Setenv("WEBUI_SECRET_KEY", originalSecret)
		} else {
			os.Unsetenv("WEBUI_SECRET_KEY")
		}
	}()

	t.Run("Integration: Multiple validations in sequence", func(t *testing.T) {
		secrets := []string{
			"first-valid-secret-key-with-sufficient-length", // pragma: allowlist secret
			"second-valid-secret-key-also-long-enough",      // pragma: allowlist secret
			"third-valid-secret-key-meets-requirements",     // pragma: allowlist secret
		}

		for _, secret := range secrets { // pragma: allowlist secret
			os.Setenv("WEBUI_SECRET_KEY", secret)
			err := validateSecrets()
			if err != nil {
				t.Errorf("Validation failed for valid secret: %v", err)
			}
		}
	})

	t.Run("Integration: Validation after env change", func(t *testing.T) {
		// Set invalid secret
		os.Setenv("WEBUI_SECRET_KEY", "short")
		err := validateSecrets()
		if err == nil {
			t.Error("Expected validation to fail with short secret")
		}

		// Change to valid secret
		os.Setenv("WEBUI_SECRET_KEY", "now-this-is-a-valid-secret-key-with-length") // pragma: allowlist secret
		err = validateSecrets()
		if err != nil {
			t.Errorf("Expected validation to succeed after fixing secret: %v", err)
		}
	})
}

func TestRequestIDMiddlewareAndRespondJSON(t *testing.T) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	c.Request = httptest.NewRequest(http.MethodGet, "/test", http.NoBody)

	mw := requestIDMiddleware()
	mw(c)

	if got := c.Writer.Header().Get("X-Request-ID"); got == "" {
		t.Fatalf("expected X-Request-ID header to be set")
	}

	// ensure respondJSON adds request_id to payload
	respondJSON(c, http.StatusOK, gin.H{"foo": "bar"})
	if w.Code != http.StatusOK {
		t.Fatalf("expected status %d, got %d", http.StatusOK, w.Code)
	}
	if body := w.Body.String(); !strings.Contains(body, "request_id") {
		t.Fatalf("expected response to include request_id, got: %s", body)
	}
}

func TestRequestLogger(t *testing.T) {
	now := time.Now()
	params := gin.LogFormatterParams{
		TimeStamp:    now,
		StatusCode:   http.StatusOK,
		Latency:      150 * time.Millisecond,
		ClientIP:     "127.0.0.1",
		Method:       http.MethodGet,
		Path:         "/health",
		Keys:         map[any]any{"request_id": "req-123"},
		ErrorMessage: "",
	}
	line := requestLogger(params)
	if !strings.Contains(line, "\"status\":200") || !strings.Contains(line, "\"request_id\":\"req-123\"") {
		t.Fatalf("unexpected log line: %s", line)
	}
}

func TestSetupRouterRoutes(t *testing.T) {
	gin.SetMode(gin.TestMode)
	secret := "this-is-a-sufficiently-long-secret-key-12345678" // pragma: allowlist secret
	os.Setenv("WEBUI_SECRET_KEY", secret)
	t.Cleanup(func() { os.Unsetenv("WEBUI_SECRET_KEY") })

	router := setupRouter()

	// Root
	w := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/", http.NoBody)
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("root expected 200, got %d", w.Code)
	}
	if !strings.Contains(w.Body.String(), "auth-service is running") {
		t.Fatalf("root body unexpected: %s", w.Body.String())
	}

	// Health
	w = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/health", http.NoBody)
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("health expected 200, got %d", w.Code)
	}

	// Validate missing token
	w = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/validate", http.NoBody)
	router.ServeHTTP(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("validate missing token expected 401, got %d", w.Code)
	}

	// Validate invalid token
	w = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/validate", http.NoBody)
	req.AddCookie(&http.Cookie{Name: "token", Value: "invalid"})
	router.ServeHTTP(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("validate invalid token expected 401, got %d", w.Code)
	}

	// Validate success
	now := time.Now()
	claims := jwt.RegisteredClaims{
		Subject:   "user-123",
		IssuedAt:  jwt.NewNumericDate(now.Add(-time.Minute)),
		ExpiresAt: jwt.NewNumericDate(now.Add(time.Hour)),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("failed to sign token: %v", err)
	}

	w = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodGet, "/validate", http.NoBody)
	req.AddCookie(&http.Cookie{Name: "token", Value: tokenString})
	router.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("validate success expected 200, got %d", w.Code)
	}
	if !strings.Contains(w.Body.String(), "authorized") {
		t.Fatalf("validate body unexpected: %s", w.Body.String())
	}
}

func TestVerifyToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	secret := "this-is-a-sufficiently-long-secret-key-12345678" // pragma: allowlist secret
	os.Setenv("WEBUI_SECRET_KEY", secret)
	t.Cleanup(func() { os.Unsetenv("WEBUI_SECRET_KEY") })

	now := time.Now()
	claims := jwt.RegisteredClaims{
		Subject:   "user-123",
		IssuedAt:  jwt.NewNumericDate(now.Add(-1 * time.Minute)),
		ExpiresAt: jwt.NewNumericDate(now.Add(10 * time.Minute)),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("failed to sign token: %v", err)
	}

	valid, err := verifyToken(tokenString)
	if err != nil || !valid {
		t.Fatalf("expected valid token, got err=%v valid=%v", err, valid)
	}
}

func TestVerifyTokenFailures(t *testing.T) {
	cases := []struct {
		name       string
		secret     string
		tokenGen   func(secret string) string
		expectErr  string
		expectBool bool
	}{
		{
			name:      "missing secret",
			secret:    "",
			tokenGen:  func(string) string { return "dummy" },
			expectErr: "WEBUI_SECRET_KEY env variable missing",
		},
		{
			name:   "missing token",
			secret: "this-is-a-sufficiently-long-secret-key-12345678",
			tokenGen: func(string) string {
				return ""
			},
			expectErr: "token missing",
		},
		{
			name:   "expired token",
			secret: "this-is-a-sufficiently-long-secret-key-12345678",
			tokenGen: func(secret string) string {
				now := time.Now()
				claims := jwt.RegisteredClaims{
					Subject:   "user-123",
					IssuedAt:  jwt.NewNumericDate(now.Add(-2 * time.Hour)),
					ExpiresAt: jwt.NewNumericDate(now.Add(-1 * time.Hour)),
				}
				token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
				s, err := token.SignedString([]byte(secret))
				if err != nil {
					t.Fatalf("failed to sign token: %v", err)
				}
				return s
			},
			expectErr: "token is expired",
		},
		{
			name:   "issuer mismatch",
			secret: "this-is-a-sufficiently-long-secret-key-12345678",
			tokenGen: func(secret string) string {
				now := time.Now()
				claims := jwt.RegisteredClaims{
					Subject:   "user-123",
					IssuedAt:  jwt.NewNumericDate(now.Add(-1 * time.Minute)),
					ExpiresAt: jwt.NewNumericDate(now.Add(1 * time.Hour)),
					Issuer:    "other",
				}
				os.Setenv("WEBUI_JWT_ISSUER", "expected")
				token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
				s, err := token.SignedString([]byte(secret))
				if err != nil {
					t.Fatalf("failed to sign token: %v", err)
				}
				return s
			},
			expectErr: "issuer mismatch",
		},
		{
			name:   "audience mismatch",
			secret: "this-is-a-sufficiently-long-secret-key-12345678",
			tokenGen: func(secret string) string {
				now := time.Now()
				claims := jwt.RegisteredClaims{
					Subject:   "user-123",
					IssuedAt:  jwt.NewNumericDate(now.Add(-1 * time.Minute)),
					ExpiresAt: jwt.NewNumericDate(now.Add(1 * time.Hour)),
					Audience:  []string{"other"},
				}
				os.Setenv("WEBUI_JWT_AUDIENCE", "expected-aud")
				token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
				s, err := token.SignedString([]byte(secret))
				if err != nil {
					t.Fatalf("failed to sign token: %v", err)
				}
				return s
			},
			expectErr: "audience mismatch",
		},
		{
			name:   "wrong algorithm",
			secret: "this-is-a-sufficiently-long-secret-key-12345678",
			tokenGen: func(secret string) string {
				now := time.Now()
				claims := jwt.RegisteredClaims{
					Subject:   "user-123",
					IssuedAt:  jwt.NewNumericDate(now.Add(-1 * time.Minute)),
					ExpiresAt: jwt.NewNumericDate(now.Add(1 * time.Hour)),
				}
				token := jwt.NewWithClaims(jwt.SigningMethodHS384, claims)
				s, err := token.SignedString([]byte(secret))
				if err != nil {
					t.Fatalf("failed to sign token: %v", err)
				}
				return s
			},
			expectErr: "signing method HS384 is invalid",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Cleanup(func() {
				os.Unsetenv("WEBUI_SECRET_KEY")
				os.Unsetenv("WEBUI_JWT_ISSUER")
				os.Unsetenv("WEBUI_JWT_AUDIENCE")
			})
			if tc.secret != "" {
				os.Setenv("WEBUI_SECRET_KEY", tc.secret)
			}
			token := tc.tokenGen(tc.secret)
			ok, err := verifyToken(token)
			if tc.expectErr == "" && err != nil {
				t.Fatalf("expected no error, got %v", err)
			}
			if tc.expectErr != "" {
				if err == nil || !strings.Contains(err.Error(), tc.expectErr) {
					t.Fatalf("expected error containing %q, got %v", tc.expectErr, err)
				}
			}
			if ok && tc.expectErr != "" {
				t.Fatalf("expected validation failure, got ok=true")
			}
		})
	}
}

func TestGetEnvOrFile(t *testing.T) {
	t.Cleanup(func() { os.Unsetenv("TEST_ENV_FILE") })

	// env value wins
	os.Setenv("TEST_ENV_FILE", "from-env")
	if got := getEnvOrFile("TEST_ENV_FILE"); got != "from-env" {
		t.Fatalf("expected env value, got %q", got)
	}

	// file fallback
	os.Unsetenv("TEST_ENV_FILE")
	tmp, err := os.CreateTemp("", "secret-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.WriteString("from-file"); err != nil {
		t.Fatal(err)
	}
	tmp.Close()

	os.Setenv("TEST_ENV_FILE_FILE", tmp.Name())
	if got := getEnvOrFile("TEST_ENV_FILE"); got != "from-file" {
		t.Fatalf("expected file value, got %q", got)
	}
}

func TestHealthCheck(t *testing.T) {
	gin.SetMode(gin.TestMode)
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/health" {
			w.WriteHeader(http.StatusOK)
			if _, err := w.Write([]byte(`{"status":"ok"}`)); err != nil {
				// Best effort in test server; log to stderr
				if _, logErr := w.Write([]byte(err.Error())); logErr != nil {
					t.Logf("health handler write error: %v", logErr)
				}
			}
			return
		}
		w.WriteHeader(http.StatusNotFound)
	}))
	t.Cleanup(ts.Close)

	os.Setenv("HEALTHCHECK_URL", ts.URL+"/health")
	t.Cleanup(func() { os.Unsetenv("HEALTHCHECK_URL") })

	if err := healthCheck(); err != nil {
		t.Fatalf("healthCheck should succeed, got %v", err)
	}
}

func TestValidateSecretsConcurrency(t *testing.T) {
	// Test that validateSecrets is safe to call concurrently
	os.Setenv("WEBUI_SECRET_KEY", "concurrent-test-secret-key-with-sufficient-length") // pragma: allowlist secret
	defer os.Unsetenv("WEBUI_SECRET_KEY")

	done := make(chan bool)
	errors := make(chan error, 10)

	for i := 0; i < 10; i++ {
		go func() {
			err := validateSecrets()
			errors <- err
			done <- true
		}()
	}

	// Wait for all goroutines
	for i := 0; i < 10; i++ {
		<-done
	}

	close(errors)

	// Check that all validations succeeded
	for err := range errors {
		if err != nil {
			t.Errorf("Concurrent validation failed: %v", err)
		}
	}
}

func BenchmarkValidateSecrets(b *testing.B) {
	os.Setenv("WEBUI_SECRET_KEY", "benchmark-secret-key-with-sufficient-length")
	defer os.Unsetenv("WEBUI_SECRET_KEY")

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if err := validateSecrets(); err != nil {
			b.Fatal(err)
		}
	}
}

func TestRunSkipServer(t *testing.T) {
	os.Setenv("SKIP_SERVER_START", "1")
	os.Setenv("WEBUI_SECRET_KEY", "this-is-a-sufficiently-long-secret-key-12345678") // pragma: allowlist secret
	t.Cleanup(func() {
		os.Unsetenv("SKIP_SERVER_START")
		os.Unsetenv("WEBUI_SECRET_KEY")
	})

	if err := run([]string{"cmd"}); err != nil {
		t.Fatalf("expected run to succeed with SKIP_SERVER_START, got %v", err)
	}
}

func TestRunHealthCheckArg(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	t.Cleanup(ts.Close)

	os.Setenv("HEALTHCHECK_URL", ts.URL)
	t.Cleanup(func() { os.Unsetenv("HEALTHCHECK_URL") })

	if err := run([]string{"cmd", "--health-check"}); err != nil {
		t.Fatalf("expected health-check arg to succeed, got %v", err)
	}
}

func TestMainEntryPoint(_ *testing.T) {
	os.Setenv("SKIP_SERVER_START", "1")
	os.Setenv("WEBUI_SECRET_KEY", "this-is-a-sufficiently-long-secret-key-12345678")
	origArgs := os.Args
	os.Args = []string{"cmd"}
	defer func() {
		os.Args = origArgs
		os.Unsetenv("SKIP_SERVER_START")
		os.Unsetenv("WEBUI_SECRET_KEY")
	}()

	main()
}

func TestValidateSecretsErrorMessages(t *testing.T) {
	tests := []struct {
		name            string
		secret          string
		expectedContain string
	}{
		{
			name:            "Empty secret error message",
			secret:          "",
			expectedContain: "not set",
		},
		{
			name:            "Short secret error message",
			secret:          "short",
			expectedContain: "too short",
		},
		{
			name:            "Short secret includes length info",
			secret:          "12345",
			expectedContain: "5 chars",
		},
		{
			name:            "Short secret includes minimum requirement",
			secret:          "tooshort",
			expectedContain: "32 characters required",
		},
		{
			name:            "Whitespace-only secret error message",
			secret:          "                                ",
			expectedContain: "only whitespace",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.secret == "" {
				os.Unsetenv("WEBUI_SECRET_KEY")
			} else {
				os.Setenv("WEBUI_SECRET_KEY", tt.secret)
			}
			defer os.Unsetenv("WEBUI_SECRET_KEY")

			err := validateSecrets()
			if err == nil {
				t.Error("Expected error but got none")
				return
			}

			if !strings.Contains(err.Error(), tt.expectedContain) {
				t.Errorf("Expected error message to contain '%s', got: %s",
					tt.expectedContain, err.Error())
			}
		})
	}
}

// Test requestLogger with different status codes and error messages.
func TestRequestLoggerVariants(t *testing.T) {
	tests := []struct {
		name         string
		statusCode   int
		errorMessage string
		expectLog    string
	}{
		{
			name:         "Success request",
			statusCode:   200,
			errorMessage: "",
			expectLog:    "\"status\":200",
		},
		{
			name:         "Error request with message",
			statusCode:   500,
			errorMessage: "internal error",
			expectLog:    "\"status\":500",
		},
		{
			name:         "Client error",
			statusCode:   400,
			errorMessage: "bad request",
			expectLog:    "\"status\":400",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			params := gin.LogFormatterParams{
				TimeStamp:    time.Now(),
				StatusCode:   tt.statusCode,
				Latency:      100 * time.Millisecond,
				ClientIP:     "127.0.0.1",
				Method:       http.MethodPost,
				Path:         "/api/test",
				ErrorMessage: tt.errorMessage,
				Keys:         map[any]any{"request_id": "test-123"},
			}

			line := requestLogger(params)
			if !strings.Contains(line, tt.expectLog) {
				t.Errorf("Expected log to contain %s, got: %s", tt.expectLog, line)
			}
			// ErrorMessage is not included in log format, just verify the line contains basic info
			if !strings.Contains(line, "\"time\":") || !strings.Contains(line, "\"method\":") {
				t.Errorf("Expected log to contain time and method, got: %s", line)
			}
		})
	}
}

// Test respondJSON error case.
func TestRespondJSONError(t *testing.T) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	// Test error status code
	respondJSON(c, http.StatusInternalServerError, gin.H{"error": "test error"})
	if w.Code != http.StatusInternalServerError {
		t.Errorf("Expected status 500, got %d", w.Code)
	}

	// Verify Content-Type header
	if ct := w.Header().Get("Content-Type"); !strings.Contains(ct, "application/json") {
		t.Errorf("Expected Content-Type to contain application/json, got %q", ct)
	}

	// Verify error message in response body
	if body := w.Body.String(); !strings.Contains(body, "test error") {
		t.Errorf("Expected response body to contain error message, got: %s", body)
	}
}

// Test main() error path.
func TestMainEntryPointError(t *testing.T) {
	// This test validates error path in run()
	origSecret := os.Getenv("WEBUI_SECRET_KEY")
	origSkip := os.Getenv("SKIP_SERVER_START")

	os.Unsetenv("WEBUI_SECRET_KEY")
	os.Unsetenv("SKIP_SERVER_START")

	defer func() {
		if origSecret != "" {
			os.Setenv("WEBUI_SECRET_KEY", origSecret)
		} else {
			os.Unsetenv("WEBUI_SECRET_KEY")
		}
		if origSkip != "" {
			os.Setenv("SKIP_SERVER_START", origSkip)
		} else {
			os.Unsetenv("SKIP_SERVER_START")
		}
	}()

	err := run([]string{"cmd"})
	if err == nil {
		t.Fatalf("Expected run() to return error when WEBUI_SECRET_KEY is missing")
	}
	if !strings.Contains(err.Error(), "secret validation failed") {
		t.Errorf("Expected secret validation error, got: %v", err)
	}
}
