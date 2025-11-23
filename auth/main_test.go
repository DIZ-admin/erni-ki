package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Test environment setup.
func TestMain(m *testing.M) {
	// Set Gin to test mode
	gin.SetMode(gin.TestMode)

	// Set test environment variables
	os.Setenv("WEBUI_SECRET_KEY", "test-secret-key-for-testing")

	// Run tests
	code := m.Run()

	// Clean up environment variables
	os.Unsetenv("WEBUI_SECRET_KEY")

	os.Exit(code)
}

// Test root endpoint.
func TestRootEndpoint(t *testing.T) {
	// Create test router
	router := setupRouter()

	// Create test request
	req, err := http.NewRequestWithContext(context.Background(), "GET", "/", http.NoBody)
	require.NoError(t, err)

	// Create ResponseRecorder to capture response
	w := httptest.NewRecorder()

	// Execute request
	router.ServeHTTP(w, req)

	// Check status code
	assert.Equal(t, http.StatusOK, w.Code)

	// Check response content
	var response map[string]any
	err = json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)

	assert.Equal(t, "auth-service is running", response["message"])
}

// Test validation with missing token.
func TestValidateEndpointMissingToken(t *testing.T) {
	router := setupRouter()

	req, err := http.NewRequestWithContext(context.Background(), "GET", "/validate", http.NoBody)
	require.NoError(t, err)

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Expect 401 Unauthorized
	assert.Equal(t, http.StatusUnauthorized, w.Code)

	var response map[string]any
	err = json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)

	assert.Equal(t, "unauthorized", response["message"])
	assert.Equal(t, "token missing", response["error"])
}

// Test validation with valid token.
func TestValidateEndpointValidToken(t *testing.T) {
	router := setupRouter()

	// Create valid JWT token
	token := createValidJWTToken(t)

	req, err := http.NewRequestWithContext(context.Background(), "GET", "/validate", http.NoBody)
	require.NoError(t, err)

	// Add token to cookie
	req.AddCookie(&http.Cookie{
		Name:  "token",
		Value: token,
	})

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Expect 200 OK
	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]any
	err = json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)

	assert.Equal(t, "authorized", response["message"])
}

// Test validation with invalid token.
func TestValidateEndpointInvalidToken(t *testing.T) {
	router := setupRouter()

	req, err := http.NewRequestWithContext(context.Background(), "GET", "/validate", http.NoBody)
	require.NoError(t, err)

	// Add invalid token
	req.AddCookie(&http.Cookie{
		Name:  "token",
		Value: "invalid.jwt.token",
	})

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	// Expect 401 Unauthorized
	assert.Equal(t, http.StatusUnauthorized, w.Code)

	var response map[string]any
	err = json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)

	assert.Equal(t, "unauthorized", response["message"])
}

// Test verifyToken function with valid token.
func TestVerifyTokenValid(t *testing.T) {
	token := createValidJWTToken(t)

	valid, err := verifyToken(token)

	assert.NoError(t, err)
	assert.True(t, valid)
}

// Test verifyToken function with invalid token.
func TestVerifyTokenInvalid(t *testing.T) {
	valid, err := verifyToken("invalid.jwt.token")

	assert.Error(t, err)
	assert.False(t, valid)
}

// Test verifyToken function with missing secret.
func TestVerifyTokenMissingSecret(t *testing.T) {
	// Temporarily remove environment variable
	originalSecret := os.Getenv("WEBUI_SECRET_KEY")
	os.Unsetenv("WEBUI_SECRET_KEY")
	defer os.Setenv("WEBUI_SECRET_KEY", originalSecret)

	token := "any.jwt.token"

	valid, err := verifyToken(token)

	assert.Error(t, err)
	assert.False(t, valid)
	assert.Contains(t, err.Error(), "JWT_SECRET env variable missing")
}

// Test verifyToken function with expired token.
func TestVerifyTokenExpired(t *testing.T) {
	token := createExpiredJWTToken(t)

	valid, err := verifyToken(token)

	assert.Error(t, err)
	assert.False(t, valid)
}

// Helper functions

// setupRouter creates a test router.
func setupRouter() *gin.Engine {
	router := gin.New()

	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "auth-service is running",
		})
	})

	router.GET("/validate", func(c *gin.Context) {
		cookieToken, err := c.Cookie("token")
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"message": "unauthorized",
				"error":   "token missing",
			})
			return
		}

		valid, err := verifyToken(cookieToken)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"message": "unauthorized",
				"error":   err.Error(),
			})
			return
		}

		if valid {
			c.JSON(http.StatusOK, gin.H{
				"message": "authorized",
			})
		}
	})

	return router
}

// createValidJWTToken creates a valid JWT token for tests.
func createValidJWTToken(t *testing.T) string {
	secret := os.Getenv("WEBUI_SECRET_KEY")
	require.NotEmpty(t, secret, "WEBUI_SECRET_KEY must be set for tests")

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": "test-user",
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(time.Hour).Unix(),
	})

	tokenString, err := token.SignedString([]byte(secret))
	require.NoError(t, err)

	return tokenString
}

// createExpiredJWTToken creates an expired JWT token for tests.
func createExpiredJWTToken(t *testing.T) string {
	secret := os.Getenv("WEBUI_SECRET_KEY")
	require.NotEmpty(t, secret, "WEBUI_SECRET_KEY must be set for tests")

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": "test-user",
		"iat": time.Now().Add(-2 * time.Hour).Unix(),
		"exp": time.Now().Add(-time.Hour).Unix(), // Expired one hour ago
	})

	tokenString, err := token.SignedString([]byte(secret))
	require.NoError(t, err)

	return tokenString
}
