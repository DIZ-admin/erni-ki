package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

//nolint:gochecknoglobals // shared fixture key for JWT tests
var tokenKey = strings.Repeat("x", 48)

func makeSignedToken(secret, issuer, subject string, expires time.Time) string {
	tkn := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.RegisteredClaims{
		Subject:   subject,
		Issuer:    issuer,
		ExpiresAt: jwt.NewNumericDate(expires),
		IssuedAt:  jwt.NewNumericDate(time.Now().Add(-1 * time.Minute)),
	})
	signed, err := tkn.SignedString([]byte(secret))
	if err != nil {
		panic(err)
	}
	return signed
}

func TestGetEnvOrFile(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("prefers direct env var", func(t *testing.T) {
		os.Setenv("WEBUI_SECRET_KEY", "direct-secret-value")
		defer os.Unsetenv("WEBUI_SECRET_KEY")

		if got := getEnvOrFile("WEBUI_SECRET_KEY"); got != "direct-secret-value" {
			t.Fatalf("expected direct env secret, got %q", got)
		}
	})

	t.Run("falls back to _FILE", func(t *testing.T) {
		tmp := t.TempDir()
		credFile := tmp + "/credential.txt"
		if err := os.WriteFile(credFile, []byte("file-credential\n"), 0o600); err != nil {
			t.Fatalf("write credential file: %v", err)
		}

		os.Unsetenv("WEBUI_SECRET_KEY")
		os.Setenv("WEBUI_SECRET_KEY_FILE", credFile)
		defer os.Unsetenv("WEBUI_SECRET_KEY_FILE")

		if got := getEnvOrFile("WEBUI_SECRET_KEY"); got != "file-credential" {
			t.Fatalf("expected file credential, got %q", got)
		}
	})
}

func TestVerifyToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	os.Setenv("WEBUI_SECRET_KEY", tokenKey)
	defer os.Unsetenv("WEBUI_SECRET_KEY")

	t.Run("valid token", func(t *testing.T) {
		os.Setenv("WEBUI_JWT_ISSUER", "erni-ki")
		defer os.Unsetenv("WEBUI_JWT_ISSUER")

		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.RegisteredClaims{
			Subject:   "user-123",
			Issuer:    "erni-ki",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(2 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(time.Now().Add(-1 * time.Minute)),
		})

		signed, err := token.SignedString([]byte(tokenKey))
		if err != nil {
			t.Fatalf("sign token: %v", err)
		}

		valid, err := verifyToken(signed)
		if err != nil {
			t.Fatalf("expected valid token, got error: %v", err)
		}
		if !valid {
			t.Fatalf("expected token to be valid")
		}
	})

	t.Run("rejects wrong alg", func(t *testing.T) {
		token := jwt.NewWithClaims(jwt.SigningMethodHS512, jwt.RegisteredClaims{
			Subject:   "user-123",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(1 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		})
		signed, signErr := token.SignedString([]byte(tokenKey))
		if signErr != nil {
			t.Fatalf("sign token: %v", signErr)
		}

		valid, err := verifyToken(signed)
		if err == nil || valid {
			t.Fatalf("expected invalid token due to alg mismatch")
		}
	})

	t.Run("rejects expired token", func(t *testing.T) {
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.RegisteredClaims{
			Subject:   "user-123",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(-1 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(time.Now().Add(-2 * time.Minute)),
		})
		signed, signErr := token.SignedString([]byte(tokenKey))
		if signErr != nil {
			t.Fatalf("sign token: %v", signErr)
		}

		valid, err := verifyToken(signed)
		if err == nil || valid {
			t.Fatalf("expected expiration failure")
		}
	})

	t.Run("issuer mismatch", func(t *testing.T) {
		os.Setenv("WEBUI_JWT_ISSUER", "expected")
		defer os.Unsetenv("WEBUI_JWT_ISSUER")

		token := makeSignedToken(tokenKey, "other", "user-123", time.Now().Add(2*time.Minute))
		valid, err := verifyToken(token)
		if err == nil || valid {
			t.Fatalf("expected issuer mismatch to fail")
		}
	})

	t.Run("missing secret", func(t *testing.T) {
		os.Unsetenv("WEBUI_SECRET_KEY")
		valid, err := verifyToken("some-token")
		if err == nil || valid {
			t.Fatalf("expected failure when secret missing")
		}
	})
}

func TestValidateSecrets(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("errors when missing", func(t *testing.T) {
		os.Unsetenv("WEBUI_SECRET_KEY")
		if err := validateSecrets(); err == nil {
			t.Fatalf("expected missing secret error")
		}
	})

	t.Run("errors when too short", func(t *testing.T) {
		os.Setenv("WEBUI_SECRET_KEY", "short")
		defer os.Unsetenv("WEBUI_SECRET_KEY")
		if err := validateSecrets(); err == nil {
			t.Fatalf("expected short secret error")
		}
	})

	t.Run("succeeds when long enough", func(t *testing.T) {
		os.Setenv("WEBUI_SECRET_KEY", tokenKey)
		defer os.Unsetenv("WEBUI_SECRET_KEY")
		if err := validateSecrets(); err != nil {
			t.Fatalf("expected success, got %v", err)
		}
	})
}

func TestRequestHelpers(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(requestIDMiddleware())

	router.GET("/echo", func(c *gin.Context) {
		respondJSON(c, http.StatusOK, gin.H{"message": "ok"})
	})

	req := httptest.NewRequest(http.MethodGet, "/echo", http.NoBody)
	req.Header.Set("X-Request-ID", "abc-123")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	if got := w.Header().Get("X-Request-ID"); got == "" {
		t.Fatalf("expected request id header to be set")
	}

	var resp map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("parse response: %v", err)
	}
	if resp["request_id"] == "" {
		t.Fatalf("expected request_id in payload")
	}
}

func TestRequestLogger(t *testing.T) {
	now := time.Now()
	line := requestLogger(gin.LogFormatterParams{
		TimeStamp:  now,
		StatusCode: http.StatusCreated,
		Latency:    time.Millisecond * 150,
		ClientIP:   "127.0.0.1",
		Method:     http.MethodPost,
		Path:       "/login",
		Keys:       map[any]any{"request_id": "req-42"},
	})

	if !strings.Contains(line, `"status":201`) || !strings.Contains(line, `"request_id":"req-42"`) {
		t.Fatalf("logger output missing expected fields: %s", line)
	}

	blank := requestLogger(gin.LogFormatterParams{
		TimeStamp:  now,
		StatusCode: http.StatusOK,
		Latency:    time.Millisecond * 10,
		ClientIP:   "127.0.0.1",
		Method:     http.MethodGet,
		Path:       "/health",
		Keys:       nil,
	})
	if !strings.Contains(blank, `"request_id":""`) {
		t.Fatalf("expected empty request_id when none provided")
	}
}

func TestSetupRouterRoutes(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := setupRouter()

	t.Run("root route", func(t *testing.T) {
		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/", http.NoBody)
		router.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected 200, got %d", w.Code)
		}
		if w.Header().Get("X-Request-ID") == "" {
			t.Fatalf("expected request id header set")
		}
	})

	t.Run("validate without token", func(t *testing.T) {
		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/validate", http.NoBody)
		router.ServeHTTP(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401 without token, got %d", w.Code)
		}
	})

	t.Run("validate with token cookie", func(t *testing.T) {
		os.Setenv("WEBUI_SECRET_KEY", tokenKey)
		defer os.Unsetenv("WEBUI_SECRET_KEY")

		token := makeSignedToken(tokenKey, "erni-ki", "user-42", time.Now().Add(2*time.Minute))
		req := httptest.NewRequest(http.MethodGet, "/validate", http.NoBody)
		req.AddCookie(&http.Cookie{Name: "token", Value: token})

		w := httptest.NewRecorder()
		router.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected 200 with valid token, got %d", w.Code)
		}
	})

	t.Run("generates request id when missing", func(t *testing.T) {
		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/", http.NoBody)
		router.ServeHTTP(w, req)

		if got := w.Header().Get("X-Request-ID"); got == "" {
			t.Fatalf("expected generated request id header")
		}
	})
}

func TestHealthCheckCustomURL(t *testing.T) {
	gin.SetMode(gin.TestMode)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	os.Setenv("AUTH_HEALTH_URL", srv.URL)
	defer os.Unsetenv("AUTH_HEALTH_URL")

	if err := healthCheck(); err != nil {
		t.Fatalf("expected health check to pass with custom URL, got %v", err)
	}
}

func TestHealthCheckFailure(t *testing.T) {
	gin.SetMode(gin.TestMode)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer srv.Close()

	os.Setenv("AUTH_HEALTH_URL", srv.URL)
	defer os.Unsetenv("AUTH_HEALTH_URL")

	if err := healthCheck(); err == nil {
		t.Fatalf("expected health check to fail on 500 status")
	}
}

func TestRunHealthCheckPath(t *testing.T) {
	gin.SetMode(gin.TestMode)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	os.Setenv("AUTH_HEALTH_URL", srv.URL)
	defer os.Unsetenv("AUTH_HEALTH_URL")

	exitCode := run([]string{"cmd", "--health-check"}, nil)
	if exitCode != 0 {
		t.Fatalf("expected health-check path to exit 0, got %d", exitCode)
	}
}

func TestRunServerInjectedServe(t *testing.T) {
	gin.SetMode(gin.TestMode)
	called := false
	exitCode := run([]string{"cmd"}, func(s *http.Server) error {
		if s == nil || s.Addr != "0.0.0.0:9090" {
			return fmt.Errorf("server not initialized")
		}
		called = true
		return nil
	})

	if exitCode != 0 {
		t.Fatalf("expected zero exit code, got %d", exitCode)
	}
	if !called {
		t.Fatalf("expected injected serve to be called")
	}
}

func TestRunServerInjectedServeFailure(t *testing.T) {
	gin.SetMode(gin.TestMode)
	exitCode := run([]string{"cmd"}, func(*http.Server) error {
		return fmt.Errorf("boom")
	})
	if exitCode == 0 {
		t.Fatalf("expected non-zero exit code on failure")
	}
}

func TestRunDefaultServerPath(t *testing.T) {
	gin.SetMode(gin.TestMode)
	orig := listenAndServe
	defer func() { listenAndServe = orig }()

	called := false
	listenAndServe = func(s *http.Server) error {
		if s.Addr != "0.0.0.0:9090" {
			return fmt.Errorf("unexpected addr: %s", s.Addr)
		}
		called = true
		return nil
	}

	if exitCode := run([]string{"cmd"}, nil); exitCode != 0 {
		t.Fatalf("expected zero exit code, got %d", exitCode)
	}
	if !called {
		t.Fatalf("expected listenAndServe to be called")
	}
}

func TestMainWrapsRun(t *testing.T) {
	gin.SetMode(gin.TestMode)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	origArgs := os.Args
	origExit := osExit
	defer func() {
		os.Args = origArgs
		osExit = origExit
	}()

	os.Args = []string{"cmd", "--health-check"}
	os.Setenv("AUTH_HEALTH_URL", srv.URL)
	defer os.Unsetenv("AUTH_HEALTH_URL")

	var exitCode int
	osExit = func(code int) { exitCode = code }

	main()

	if exitCode != 0 {
		t.Fatalf("expected main to exit with 0, got %d", exitCode)
	}
}
