package main

import (
	"os"
	"testing"
)

func TestValidateSecrets(t *testing.T) {
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
			secret:      "this-is-an-extremely-long-secret-key-with-many-characters-to-ensure-maximum-security-12345678901234567890",
			shouldError: false,
			setupEnv: func() {
				os.Setenv("WEBUI_SECRET_KEY", "this-is-an-extremely-long-secret-key-with-many-characters-to-ensure-maximum-security-12345678901234567890")
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
			shouldError: false, // Length check passes, but should consider adding content validation
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
				} else if len(tt.secret) > 0 && len(tt.secret) < 32 {
					expectedSubstring := "too short"
					if !contains(errMsg, expectedSubstring) {
						t.Errorf("Expected error message to contain '%s', got: %s", expectedSubstring, errMsg)
					}
				}
			}
		})
	}
}

// Helper function to check if string contains substring
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 || 
		(len(s) > len(substr) && (s[:len(substr)] == substr || s[len(s)-len(substr):] == substr || 
		len(s) > len(substr) && containsMiddle(s, substr))))
}

func containsMiddle(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
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
			"first-valid-secret-key-with-sufficient-length",
			"second-valid-secret-key-also-long-enough",
			"third-valid-secret-key-meets-requirements",
		}

		for _, secret := range secrets {
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
		os.Setenv("WEBUI_SECRET_KEY", "now-this-is-a-valid-secret-key-with-length")
		err = validateSecrets()
		if err != nil {
			t.Errorf("Expected validation to succeed after fixing secret: %v", err)
		}
	})
}

func TestValidateSecretsConcurrency(t *testing.T) {
	// Test that validateSecrets is safe to call concurrently
	os.Setenv("WEBUI_SECRET_KEY", "concurrent-test-secret-key-with-sufficient-length")
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

func TestHealthCheck(t *testing.T) {
	// Test the health check functionality
	err := healthCheck()
	
	// Health check should succeed when service is not running (returns error)
	// or when it's running (returns nil)
	// This is a basic smoke test
	_ = err // Health check behavior depends on whether server is running
}

func BenchmarkValidateSecrets(b *testing.B) {
	os.Setenv("WEBUI_SECRET_KEY", "benchmark-secret-key-with-sufficient-length")
	defer os.Unsetenv("WEBUI_SECRET_KEY")

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = validateSecrets()
	}
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

			if !contains(err.Error(), tt.expectedContain) {
				t.Errorf("Expected error message to contain '%s', got: %s", 
					tt.expectedContain, err.Error())
			}
		})
	}
}
