package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

func main() {
	// Check command line arguments for health check
	if len(os.Args) > 1 && os.Args[1] == "--health-check" {
		if err := healthCheck(); err != nil {
			log.Printf("health check failed: %v", err)
			os.Exit(1)
		}
		os.Exit(0)
	}

	r := gin.New()

	r.Use(requestIDMiddleware())
	r.Use(gin.LoggerWithFormatter(requestLogger))
	r.Use(gin.Recovery())

	r.GET("/", func(c *gin.Context) {
		respondJSON(c, http.StatusOK, gin.H{
			"message": "auth-service is running",
			"version": "1.0.0",
			"status":  "healthy",
		})
	})

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		respondJSON(c, http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "auth-service",
		})
	})

	r.GET("/validate", func(c *gin.Context) {
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
	})

	server := &http.Server{
		Addr:              "0.0.0.0:9090",
		Handler:           r,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	if err := server.ListenAndServe(); err != nil {
		log.Printf("failed to start server: %v", err)
		os.Exit(1)
	}
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
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(
		ctx,
		http.MethodGet,
		"http://localhost:9090/health",
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
	jwtSecret := os.Getenv("WEBUI_SECRET_KEY")

	if jwtSecret == "" {
		return false, fmt.Errorf("WEBUI_SECRET_KEY env variable missing")
	}

	mySigningKey := []byte(jwtSecret)

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("error parsing jwt")
		}
		return mySigningKey, nil
	})
	if err != nil {
		return false, err
	}

	return token.Valid, nil
}
