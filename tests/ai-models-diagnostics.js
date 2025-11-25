/**
 * ERNI-KI AI Models Diagnostics with Playwright
 * Comprehensive AI models functionality diagnostics
 *
 * @author Alteon Schultz (Tech Lead)
 * @version 1.0.0
 */
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Test configuration
const CONFIG = {
  baseUrl: 'http://localhost:8080',
  timeout: 30000,
  screenshotsDir: './test-results/screenshots',
  reportsDir: './test-results/reports',
  expectedModels: ['gpt-oss:20b', 'gemma3n:e4b', 'nomic-embed-text:latest'],
  testPrompts: [
    'Hello! How are you?',
    'Explain quantum physics in two sentences.',
    'Find the latest news in the AI industry.',
  ],
  maxResponseTime: 5000, // 5 seconds
  ragTestQuery: 'Find the latest news about artificial intelligence',
};

class AIModelsDiagnostics {
  constructor() {
    this.browser = null;
    this.page = null;
    this.results = {
      timestamp: new Date().toISOString(),
      systemStatus: {},
      modelTests: [],
      performanceMetrics: {},
      ragTests: [],
      errors: [],
      recommendations: [],
    };

    // Create directories for results
    this.ensureDirectories();
  }

  ensureDirectories() {
    [CONFIG.screenshotsDir, CONFIG.reportsDir].forEach(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    });
  }

  async initialize() {
    console.log('🚀 Initializing Playwright browser...');

    this.browser = await chromium.launch({
      headless: false, // Show browser for debugging
      slowMo: 1000, // Slow down for observation
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });

    this.page = await this.browser.newPage();

    // Configure timeouts
    this.page.setDefaultTimeout(CONFIG.timeout);

    // Intercept console messages
    this.page.on('console', msg => {
      if (msg.type() === 'error') {
        this.results.errors.push({
          type: 'console_error',
          message: msg.text(),
          timestamp: new Date().toISOString(),
        });
      }
    });

    console.log('✅ Browser initialized');
  }

  async navigateToOpenWebUI() {
    console.log('🌐 Navigating to OpenWebUI...');

    try {
      await this.page.goto(CONFIG.baseUrl, { waitUntil: 'networkidle' });

      // Screenshot of main page
      await this.takeScreenshot('01-main-page');

      // Check page load
      const title = await this.page.title();
      console.log(`📄 Page title: ${title}`);

      this.results.systemStatus.webUIAccessible = true;
      this.results.systemStatus.pageTitle = title;
    } catch (error) {
      this.results.errors.push({
        type: 'navigation_error',
        message: error.message,
        timestamp: new Date().toISOString(),
      });
      throw error;
    }
  }

  async checkAvailableModels() {
    console.log('🤖 Checking available models...');

    try {
      // Wait for interface load
      await this.page.waitForSelector('[data-testid="model-selector"], .model-selector, select', {
        timeout: 10000,
      });

      // Search for model selector (various options)
      const modelSelectors = [
        '[data-testid="model-selector"]',
        '.model-selector',
        'select[name*="model"]',
        'button[aria-label*="model"]',
        '.dropdown-toggle',
      ];

      let modelSelector = null;
      for (const selector of modelSelectors) {
        const element = await this.page.$(selector);
        if (element) {
          modelSelector = selector;
          break;
        }
      }

      if (!modelSelector) {
        throw new Error('Model selector not found');
      }

      // Click on model selector
      await this.page.click(modelSelector);
      await this.page.waitForTimeout(2000);

      // Screenshot of models list
      await this.takeScreenshot('02-models-list');

      // Get list of available models
      const models = await this.page.$$eval('option, .dropdown-item, [role="option"]', elements =>
        elements.map(el => el.textContent?.trim()).filter(Boolean),
      );

      console.log(`📋 Models found: ${models.length}`);
      models.forEach(model => console.log(`  - ${model}`));

      this.results.systemStatus.availableModels = models;
      this.results.systemStatus.modelsCount = models.length;

      // Check expected models
      const missingModels = CONFIG.expectedModels.filter(
        expected => !models.some(available => available.includes(expected.split(':')[0])),
      );

      if (missingModels.length > 0) {
        this.results.errors.push({
          type: 'missing_models',
          message: `Missing models: ${missingModels.join(', ')}`,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (error) {
      this.results.errors.push({
        type: 'models_check_error',
        message: error.message,
        timestamp: new Date().toISOString(),
      });
      console.error('❌ Error checking models:', error.message);
    }
  }

  async testTextGeneration() {
    console.log('✍️ Testing text generation...');

    for (const prompt of CONFIG.testPrompts) {
      console.log(`📝 Testing prompt: "${prompt}"`);

      try {
        const startTime = Date.now();

        // Search for input field
        const inputSelectors = [
          'textarea[placeholder*="message"]',
          '.chat-input textarea',
          'input[type="text"]',
          '[contenteditable="true"]',
        ];

        let inputSelector = null;
        for (const selector of inputSelectors) {
          const element = await this.page.$(selector);
          if (element) {
            inputSelector = selector;
            break;
          }
        }

        if (!inputSelector) {
          throw new Error('Input field not found');
        }

        // Enter text
        await this.page.fill(inputSelector, prompt);
        await this.page.waitForTimeout(1000);

        // Search for send button
        const sendSelectors = [
          'button[type="submit"]',
          'button[aria-label*="send"]',
          '.send-button',
          '[data-testid="send-button"]',
        ];

        let sendButton = null;
        for (const selector of sendSelectors) {
          const element = await this.page.$(selector);
          if (element) {
            sendButton = selector;
            break;
          }
        }

        if (!sendButton) {
          // Try Enter
          await this.page.press(inputSelector, 'Enter');
        } else {
          await this.page.click(sendButton);
        }

        // Wait for response
        await this.page.waitForSelector('.message, .chat-message, .response', {
          timeout: CONFIG.maxResponseTime,
        });

        const responseTime = Date.now() - startTime;

        // Get response
        const responses = await this.page.$$eval('.message, .chat-message, .response', elements =>
          elements.map(el => el.textContent?.trim()).filter(Boolean),
        );

        const lastResponse = responses[responses.length - 1];

        this.results.modelTests.push({
          prompt,
          response: lastResponse?.substring(0, 200) + '...',
          responseTime,
          success: true,
          timestamp: new Date().toISOString(),
        });

        console.log(`✅ Response received in ${responseTime}ms`);

        // Screenshot of dialog
        await this.takeScreenshot(`03-chat-${this.results.modelTests.length}`);

        await this.page.waitForTimeout(2000);
      } catch (error) {
        this.results.modelTests.push({
          prompt,
          response: null,
          responseTime: null,
          success: false,
          error: error.message,
          timestamp: new Date().toISOString(),
        });

        console.error(`❌ Error testing prompt "${prompt}":`, error.message);
      }
    }
  }

  async testRAGIntegration() {
    console.log('🔍 Testing RAG integration...');

    try {
      // Search for RAG or web search settings
      const ragSelectors = [
        '[data-testid="web-search"]',
        '.web-search-toggle',
        'input[type="checkbox"][name*="search"]',
        'button[aria-label*="search"]',
      ];

      let ragToggle = null;
      for (const selector of ragSelectors) {
        const element = await this.page.$(selector);
        if (element) {
          ragToggle = selector;
          break;
        }
      }

      if (ragToggle) {
        await this.page.click(ragToggle);
        console.log('🔍 RAG/web search enabled');
      }

      // Testing RAG query
      const startTime = Date.now();

      const inputSelector = ['textarea[placeholder*="message"]', '.chat-input textarea'].join(', ');
      await this.page.fill(inputSelector, CONFIG.ragTestQuery);

      const sendButton = 'button[type="submit"], .send-button';
      await this.page.click(sendButton);

      // Wait for response with references
      await this.page.waitForSelector('.message, .chat-message, .response', { timeout: 15000 });

      const responseTime = Date.now() - startTime;

      // Collect sources
      const collectSources = elements =>
        elements.map(el => el.textContent || el.href).filter(Boolean);

      const sources = await this.page.$$eval('.source, .citation, [href*="http"]', collectSources);

      this.results.ragTests.push({
        query: CONFIG.ragTestQuery,
        responseTime,
        sourcesFound: sources.length,
        sources: sources.slice(0, 5), // First five sources
        success: true,
        timestamp: new Date().toISOString(),
      });

      console.log(`✅ RAG test completed. Sources found: ${sources.length}`);

      // Screenshot of the RAG response
      await this.takeScreenshot('04-rag-response');
    } catch (error) {
      this.results.ragTests.push({
        query: CONFIG.ragTestQuery,
        responseTime: null,
        sourcesFound: 0,
        sources: [],
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      });

      console.error('❌ Error testing RAG:', error.message);
    }
  }

  async takeScreenshot(name) {
    const filename = `${name}-${Date.now()}.png`;
    const filepath = path.join(CONFIG.screenshotsDir, filename);
    await this.page.screenshot({ path: filepath, fullPage: true });
    console.log(`📸 Screenshot saved: ${filename}`);
  }

  async generateReport() {
    console.log('📊 Generating report...');

    // Calculate performance metrics
    const successfulTests = this.results.modelTests.filter(test => test.success);
    const avgResponseTime =
      successfulTests.length > 0
        ? successfulTests.reduce((sum, test) => sum + test.responseTime, 0) / successfulTests.length
        : 0;

    this.results.performanceMetrics = {
      totalTests: this.results.modelTests.length,
      successfulTests: successfulTests.length,
      failedTests: this.results.modelTests.length - successfulTests.length,
      averageResponseTime: Math.round(avgResponseTime),
      ragTestsSuccessful: this.results.ragTests.filter(test => test.success).length,
      totalErrors: this.results.errors.length,
    };

    // Build recommendations
    this.generateRecommendations();

    // Persist report
    const reportPath = path.join(CONFIG.reportsDir, `ai-diagnostics-${Date.now()}.json`);
    fs.writeFileSync(reportPath, JSON.stringify(this.results, null, 2));

    console.log(`📋 Report saved: ${reportPath}`);

    // Print brief summary to the console
    this.printSummary();
  }

  generateRecommendations() {
    const { performanceMetrics, errors } = this.results;

    if (performanceMetrics.averageResponseTime > CONFIG.maxResponseTime) {
      this.results.recommendations.push(
        'Response time exceeds the expected threshold. Consider optimizing the GPU or model.',
      );
    }

    if (performanceMetrics.failedTests > 0) {
      this.results.recommendations.push('Some tests failed. Review the Ollama and OpenWebUI logs.');
    }

    if (errors.some(error => error.type === 'missing_models')) {
      this.results.recommendations.push(
        'Expected models are missing. Pull the required models through Ollama.',
      );
    }

    if (this.results.ragTests.length === 0 || !this.results.ragTests.some(test => test.success)) {
      this.results.recommendations.push(
        'RAG integration failed. Inspect SearXNG and the web-search configuration.',
      );
    }
  }

  printSummary() {
    console.log('\n' + '='.repeat(60));
    console.log('📊 AI MODELS DIAGNOSTICS SUMMARY');
    console.log('='.repeat(60));

    const { systemStatus, performanceMetrics } = this.results;

    console.log(`🌐 OpenWebUI accessible: ${systemStatus.webUIAccessible ? '✅' : '❌'}`);
    console.log(`🤖 Models available: ${systemStatus.modelsCount || 0}`);
    console.log(
      `✅ Successful tests: ${performanceMetrics.successfulTests}/${performanceMetrics.totalTests}`,
    );
    console.log(`⏱️  Average response time: ${performanceMetrics.averageResponseTime}ms`);
    console.log(`🔍 RAG tests: ${performanceMetrics.ragTestsSuccessful} successful`);
    console.log(`❌ Total errors: ${performanceMetrics.totalErrors}`);

    if (this.results.recommendations.length > 0) {
      console.log('\n📋 RECOMMENDATIONS:');
      this.results.recommendations.forEach((rec, index) => {
        console.log(`${index + 1}. ${rec}`);
      });
    }

    console.log('\n' + '='.repeat(60));
  }

  async cleanup() {
    if (this.browser) {
      await this.browser.close();
      console.log('🧹 Browser closed');
    }
  }

  async run() {
    try {
      await this.initialize();
      await this.navigateToOpenWebUI();
      await this.checkAvailableModels();
      await this.testTextGeneration();
      await this.testRAGIntegration();
      await this.generateReport();
    } catch (error) {
      console.error('💥 Critical error:', error.message);
      this.results.errors.push({
        type: 'critical_error',
        message: error.message,
        timestamp: new Date().toISOString(),
      });
    } finally {
      await this.cleanup();
    }
  }
}

// Standalone diagnostics execution
if (require.main === module) {
  const diagnostics = new AIModelsDiagnostics();
  diagnostics.run().catch(console.error);
}

module.exports = AIModelsDiagnostics;
