package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

func main() {
	if err := run(os.Args); err != nil {
		log.Printf("auth-service exited with error: %v", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	// Check command line arguments for health check
	if len(args) > 1 && args[1] == "--health-check" {
		if err := healthCheck(); err != nil {
			return fmt.Errorf("health check failed: %w", err)
		}
		return nil
	}

	if err := validateSecrets(); err != nil {
		return fmt.Errorf("secret validation failed: %w", err)
	}

	r := setupRouter()

	server := &http.Server{
		Addr:              "0.0.0.0:9090",
		Handler:           r,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	if os.Getenv("SKIP_SERVER_START") == "1" {
		return nil
	}

	if err := server.ListenAndServe(); err != nil {
		return fmt.Errorf("failed to start server: %w", err)
	}

	return nil
}

func setupRouter() *gin.Engine {
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()

	r.Use(requestIDMiddleware())
	r.Use(gin.LoggerWithFormatter(requestLogger))
	r.Use(gin.Recovery())

	registerRoutes(r)

	return r
}

func registerRoutes(r *gin.Engine) {
	r.GET("/", indexHandler)
	r.GET("/health", healthHandler)
	r.GET("/validate", validateHandler)
}

func indexHandler(c *gin.Context) {
	respondJSON(c, http.StatusOK, gin.H{
		"message": "auth-service is running",
		"version": "1.0.0",
		"status":  "healthy",
	})
}

func healthHandler(c *gin.Context) {
	respondJSON(c, http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "auth-service",
	})
}

func validateHandler(c *gin.Context) {
	cookieToken, err := c.Cookie("token")
	if err != nil {
		respondJSON(c, http.StatusUnauthorized, gin.H{
			"message": "unauthorized",
			"error":   "token missing",
		})
		return
	}

	valid, err := verifyToken(cookieToken)
	if err != nil || !valid {
		if err != nil {
			log.Printf("token verification failed: %v", err)
		}
		respondJSON(c, http.StatusUnauthorized, gin.H{
			"message": "unauthorized",
			"error":   "invalid token",
		})
		return
	}

	respondJSON(c, http.StatusOK, gin.H{
		"message": "authorized",
	})
}

func requestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		reqID := c.GetHeader("X-Request-ID")
		if reqID == "" {
			reqID = uuid.NewString()
		}
		c.Set("request_id", reqID)
		c.Writer.Header().Set("X-Request-ID", reqID)
		c.Next()
	}
}

func requestLogger(param gin.LogFormatterParams) string { //nolint:gocritic
	reqID, ok := param.Keys["request_id"].(string)
	if !ok {
		reqID = ""
	}
	return fmt.Sprintf(
		"{\"time\":%q,\"status\":%d,\"latency_ms\":%.2f,\"client\":%q,\"method\":%q,\"path\":%q,\"request_id\":%q}\n",
		param.TimeStamp.Format(time.RFC3339Nano),
		param.StatusCode,
		float64(param.Latency)/float64(time.Millisecond),
		param.ClientIP,
		param.Method,
		param.Path,
		reqID,
	)
}

func respondJSON(c *gin.Context, status int, payload gin.H) {
	if payload == nil {
		payload = gin.H{}
	}
	if _, exists := payload["request_id"]; !exists {
		payload["request_id"] = c.GetString("request_id")
	}
	c.JSON(status, payload)
}

// healthCheck performs service health check for Docker.
func healthCheck() error {
	target := os.Getenv("HEALTHCHECK_URL")
	if target == "" {
		target = os.Getenv("AUTH_HEALTH_URL")
	}
	if target == "" {
		target = "http://localhost:9090/health"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodGet,
		target,
		http.NoBody,
	)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}

	client := &http.Client{
		Timeout: 3 * time.Second,
	}

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("health check failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("health check failed with status: %d", resp.StatusCode)
	}

	fmt.Println("Health check passed")
	return nil
}

func verifyToken(tokenString string) (bool, error) {
	jwtSecret := getEnvOrFile("WEBUI_SECRET_KEY")

	if jwtSecret == "" {
		return false, fmt.Errorf("WEBUI_SECRET_KEY env variable missing")
	}

	const (
		maxTokenLength    = 4096
		requiredAlgorithm = "HS256"
	)

	if strings.TrimSpace(tokenString) == "" {
		return false, fmt.Errorf("token missing")
	}

	if len(tokenString) > maxTokenLength {
		return false, fmt.Errorf("token too long")
	}

	mySigningKey := []byte(jwtSecret)

	parser := jwt.NewParser(jwt.WithValidMethods([]string{requiredAlgorithm}))
	claims := &jwt.RegisteredClaims{}

	token, err := parser.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (any, error) {
		if method := token.Method.Alg(); method != requiredAlgorithm {
			return nil, fmt.Errorf("unexpected signing algorithm: %s", method)
		}
		return mySigningKey, nil
	})
	if err != nil {
		return false, err
	}

	if !token.Valid {
		return false, fmt.Errorf("token invalid")
	}

	now := time.Now()

	if claims.ExpiresAt == nil || now.After(claims.ExpiresAt.Time) {
		return false, fmt.Errorf("exp claim invalid or expired")
	}

	if claims.IssuedAt == nil || claims.IssuedAt.Time.After(now) {
		return false, fmt.Errorf("iat claim invalid")
	}

	if strings.TrimSpace(claims.Subject) == "" {
		return false, fmt.Errorf("sub claim missing or empty")
	}

	if expectedIssuer := os.Getenv("WEBUI_JWT_ISSUER"); expectedIssuer != "" {
		if claims.Issuer != expectedIssuer {
			return false, fmt.Errorf("issuer mismatch")
		}
	}

	return true, nil
}

// validateSecrets ensures WEBUI_SECRET_KEY is present and sufficiently long.
// Minimum length chosen to discourage weak secrets used for JWT signing.
func validateSecrets() error {
	secret := getEnvOrFile("WEBUI_SECRET_KEY")
	if secret == "" {
		return fmt.Errorf("CRITICAL: WEBUI_SECRET_KEY environment variable not set")
	}

	if len(secret) < 32 {
		return fmt.Errorf("WEBUI_SECRET_KEY too short: %d chars, 32 characters required", len(secret))
	}

	return nil
}

func getEnvOrFile(key string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}

	filePath := os.Getenv(key + "_FILE")
	if filePath == "" {
		return ""
	}

	data, err := os.Open(filePath)
	if err != nil {
		return ""
	}
	defer data.Close()

	content, err := io.ReadAll(data)
	if err != nil {
		return ""
	}

	return strings.TrimSpace(string(content))
}
