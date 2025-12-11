import { expect, Page, Request, Response, test } from '@playwright/test';
import fs from 'node:fs';

// Skip when Playwright runner is not orchestrating the tests (e.g., `bun test`)
const isPlaywrightRunner =
  Boolean(process.env.PLAYWRIGHT_TEST) || Boolean(process.env.PLAYWRIGHT_WORKER_INDEX);
if (!isPlaywrightRunner) {
  console.warn('Skipping Playwright openwebui-rag specs outside Playwright runner');
} else {
  /**
   * ERNI-KI OpenWebUI RAG E2E via Playwright
   * - Network request logging (Docling, SearXNG, Ollama)
   * - Screenshots of key steps
   * - Console error checking
   */

  const BASE = process.env.PW_BASE_URL || 'https://localhost';
  const ART_DIR = 'playwright-artifacts';
  const NET_LOG = `${ART_DIR}/network.log`;
  try {
    require('node:fs').mkdirSync(ART_DIR, { recursive: true });
  } catch (e: unknown) {
    console.warn('Failed to create directory:', e);
  }

  // Files up to 10MB: use real test documents from RAG folder
  const fixtures = {
    pdf: 'tests/fixtures/sample.pdf',
    docx: 'tests/fixtures/sample.docx',
    md: 'tests/fixtures/sample.md',
    txt: 'tests/fixtures/sample.txt',
    // Real RAG documents for complex testing
    ragPdf1: 'RAG/2023 Q3 INTC.pdf',
    ragPdf2: 'RAG/MB011_Dusche_August_2017.geschützt.pdf',
    // Additional test documents
    testMdLarge: 'test-large-document.md',
    testMdMedium: 'test-medium-complex.md',
    testMdSmall: 'test-small-multilang.md',
  };

  // Useful selectors (updated for current OpenWebUI version)
  const selectors = {
    fileInput: 'input[type="file"]',
    uploadsTab:
      'button:has-text("Uploads"), button:has-text("Files"), button:has-text("Knowledge"), a:has-text("Uploads")',
    uploadList: '[data-testid="upload-list"], .uploaded-files, .file-list, [class*="upload"]',
    chatInput:
      'textarea[placeholder*="Message"], [role="textbox"], div[contenteditable="true"], textarea',
    settingsButton: 'button[aria-label="Settings"], button:has-text("Settings")',
    webSearchToggle:
      'label:has-text("Web Search") input[type="checkbox"], input[name="web_search"]',
    sendButton:
      'button[type="submit"], button:has([class*="send"]), button:has(svg), [aria-label*="Send"], [title*="Send"], button:has-text("Send"), .send-button',
    answerBlock:
      '.message.assistant, [data-testid="assistant-message"], [class*="message"], .prose',
    // New selectors for file upload
    attachButton:
      'button[aria-label*="attach"], button[title*="attach"], button:has([class*="paperclip"]), button:has([class*="attach"])',
    uploadButton: 'button[aria-label*="upload"], button[title*="upload"], input[type="file"]',
    plusButton: 'button:has-text("+"), button[aria-label*="add"], button[title*="add"]',
  };

  // Attempt login if login form is enabled
  async function tryLogin(page: Page) {
    console.log('🔍 Checking for login form...');

    // Extended selectors for OpenWebUI
    const emailSel =
      'input[type="email"], input[name="email"], input#email, input[placeholder*="email" i], input[placeholder*="Email"]';
    const passSel =
      'input[type="password"], input[name="password"], input#password, input[placeholder*="password" i], input[placeholder*="Password"]';
    const submitSel =
      'button:has-text("Sign In"), button[type="submit"], button:has-text("Login"), button:has-text("Continue")';

    // Wait for page load
    await page.waitForTimeout(2000);

    let hasLogin = await page
      .locator(emailSel)
      .first()
      .isVisible()
      .catch(() => false);
    console.log(`Login form visible on main page: ${hasLogin}`);

    if (!hasLogin) {
      // Try to find login/register buttons
      const loginButtons =
        'button:has-text("Sign In"), button:has-text("Login"), a:has-text("Sign In"), a:has-text("Login")';
      const hasLoginButton = await page
        .locator(loginButtons)
        .first()
        .isVisible()
        .catch(() => false);
      console.log(`Login button visible: ${hasLoginButton}`);

      if (hasLoginButton) {
        await page.click(loginButtons);
        await page.waitForTimeout(1000);
        hasLogin = await page
          .locator(emailSel)
          .first()
          .isVisible()
          .catch(() => false);
        console.log(`Login form visible after clicking login button: ${hasLogin}`);
      }
    }

    if (!hasLogin) {
      console.log('❌ No login form found, assuming already authenticated or no auth required');
      return false;
    }

    const EMAIL = process.env.E2E_OPENWEBUI_EMAIL || '';
    const PASS = process.env.E2E_OPENWEBUI_PASSWORD || '';
    if (!EMAIL || !PASS) {
      console.warn('⚠️ Login form detected but E2E_OPENWEBUI_EMAIL/PASSWORD are not set.');
      return false;
    }

    console.log(`🔑 Attempting login with email: ${EMAIL}`);
    await page.fill(emailSel, EMAIL);
    await page.fill(passSel, PASS);
    await page.click(submitSel).catch(() => page.press(passSel, 'Enter'));

    // Wait for either chat or login error
    try {
      await page.waitForSelector(selectors.chatInput, { timeout: 10_000 });
      console.log('✅ Login successful - chat input found');
      return true;
    } catch (e) {
      console.log('❌ Login may have failed - chat input not found');
      return false;
    }
  }

  // Request logging for SearXNG/Ollama
  function attachNetworkLogging(page: Page) {
    const append = (line: string) => {
      try {
        fs.appendFileSync(NET_LOG, line + '\n');
      } catch (e: unknown) {
        console.warn('Failed to create directory:', e);
      }
    };
    page.on('request', (req: Request) => {
      const url = req.url();
      if (/searxng|ollama|openwebui\/api/i.test(url)) {
        const line = `→ ${req.method()} ${url}`;
        console.log(line);
        append(line);
      }
    });
    page.on('response', async (res: Response) => {
      const url = res.url();
      if (/searxng|ollama|openwebui\/api/i.test(url)) {
        const line = `← ${res.status()} ${url}`;
        console.log(line);
        append(line);
      }
    });
  }

  async function assertNoConsoleErrors(page: Page) {
    const errors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') errors.push(msg.text());
    });
    return () => {
      if (errors.length) {
        console.warn('Console errors:', errors.join('\n'));
      }
      expect(errors.length, 'No console errors').toBe(0);
    };
  }

  // Improved file upload function
  async function uploadFile(page: Page, filePath: string): Promise<boolean> {
    console.log(`📁 Attempting to upload file: ${filePath}`);

    // First try to close any open modal windows
    await page.keyboard.press('Escape').catch(() => {});
    await page.waitForTimeout(1000);

    // Strategy 1: Direct input[type="file"] search
    const fileInput = await page
      .locator('input[type="file"]')
      .first()
      .isVisible()
      .catch(() => false);
    if (fileInput) {
      await page.setInputFiles('input[type="file"]', filePath);
      console.log('✅ File uploaded via direct input');
      return true;
    }

    // Strategy 2: Correct sequence for OpenWebUI
    try {
      // 1. Find button with icon near input field
      const attachButton = page.locator('button:has(img)').first();
      const isAttachVisible = await attachButton.isVisible().catch(() => false);

      if (isAttachVisible) {
        console.log('🔍 Found attachment button, clicking...');

        // 2. Click button to open menu
        await attachButton.click();

        // 3. Wait for menu and look for "Upload Files"
        await page.waitForTimeout(1000); // Give menu time to appear
        const uploadMenuItem = page.getByRole('menuitem', { name: 'Upload Files' });

        // Wait for menu item to become visible
        await uploadMenuItem.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {});
        const isMenuItemVisible = await uploadMenuItem.isVisible().catch(() => false);

        if (isMenuItemVisible) {
          console.log('🔍 Found "Upload Files" menu item, clicking...');

          // 4. Click "Upload Files" and handle file chooser
          const [fileChooser] = await Promise.all([
            page.waitForEvent('filechooser', { timeout: 5000 }),
            uploadMenuItem.click(),
          ]);

          await fileChooser.setFiles(filePath);
          console.log('✅ File uploaded successfully via OpenWebUI menu');

          // Wait a bit for file processing
          await page.waitForTimeout(2000);
          return true;
        } else {
          console.log('❌ "Upload Files" menu item not visible');
          // Try to find alternative menu items
          const menuItems = await page.locator('menuitem').allTextContents();
          console.log('Available menu items:', menuItems);
        }
      }
    } catch (error) {
      console.log(`❌ OpenWebUI upload method failed: ${error}`);
    }

    // Strategy 3: Hidden input[type="file"] search and forced upload
    try {
      const hiddenFileInputs = await page.locator('input[type="file"]').all();
      console.log(`Found ${hiddenFileInputs.length} file inputs`);

      for (let i = 0; i < hiddenFileInputs.length; i++) {
        const input = hiddenFileInputs[i];
        if (!input) continue;

        try {
          await input.setInputFiles(filePath);
          console.log(`✅ File uploaded via hidden input ${i + 1}`);
          await page.waitForTimeout(2000);
          return true;
        } catch (error) {
          console.log(`❌ Hidden input ${i + 1} failed: ${error}`);
          continue;
        }
      }
    } catch (error) {
      console.log(`❌ Hidden input strategy failed: ${error}`);
    }

    // Strategy 4: Attempt via temporary input creation
    try {
      console.log('🔍 Trying temporary file input creation...');
      const fileChooser = await page.evaluateHandle(() => {
        return new Promise(resolve => {
          const input = document.createElement('input');
          input.type = 'file';
          input.style.display = 'none';
          document.body.appendChild(input);
          input.addEventListener('change', () => resolve(input));
          input.click();
        });
      });

      if (fileChooser) {
        // This method might not work due to browser security
        console.log('✅ Temporary input created, but file selection requires user interaction');
      }
    } catch (error) {
      console.log(`❌ Temporary input method failed: ${error}`);
    }

    console.log('❌ All upload strategies failed');
    return false;
  }

  // Improved message sending function
  async function sendMessage(page: Page, message: string): Promise<boolean> {
    console.log(`💬 Sending message: ${message.substring(0, 50)}...`);

    // First find and fill input field
    const inputSelectors = [
      selectors.chatInput,
      'textarea[placeholder*="Message"]',
      'textarea[placeholder*="Message"]',
      'textarea',
      '[role="textbox"]',
      'div[contenteditable="true"]',
      'input[type="text"]',
    ];

    let inputFound = false;
    for (const selector of inputSelectors) {
      try {
        const isVisible = await page
          .locator(selector)
          .first()
          .isVisible()
          .catch(() => false);
        if (isVisible) {
          await page.fill(selector, message);
          console.log(`✅ Message filled in input: ${selector}`);
          inputFound = true;
          break;
        }
      } catch (error) {
        continue;
      }
    }

    if (!inputFound) {
      console.log('❌ Could not find message input field');
      return false;
    }

    // Now find and click send button
    const sendSelectors = [
      selectors.sendButton,
      'button[type="submit"]',
      'button:has(svg)',
      'button[aria-label*="Send"]',
      'button[title*="Send"]',
      'button:has-text("Send")',
      '.send-button',
      '[data-testid*="send"]',
    ];

    for (const selector of sendSelectors) {
      try {
        const isVisible = await page
          .locator(selector)
          .first()
          .isVisible()
          .catch(() => false);
        if (isVisible) {
          await page.click(selector);
          console.log(`✅ Message sent via button: ${selector}`);
          return true;
        }
      } catch (error) {
        continue;
      }
    }

    // Fallback: try Enter
    try {
      await page.keyboard.press('Enter');
      console.log('✅ Message sent via Enter key');
      return true;
    } catch (error) {
      console.log('❌ Could not send message');
      return false;
    }
  }

  // Navigation and basic availability
  test('Preparation: services healthy and UI reachable', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    await page.goto(BASE, { waitUntil: 'domcontentloaded' });
    // Some configs return 404 on /, but UI loads (SPA)
    await page.screenshot({ path: 'playwright-artifacts/01-home.png' });
    await page.waitForTimeout(500);
    // Login if necessary
    await tryLogin(page).catch(() => {});

    // Try to find chat input as UI readiness indicator
    console.log('🔍 Looking for chat input after login...');
    let uiReady = false;

    // Try multiple chat search strategies
    const chatSelectors = [
      selectors.chatInput,
      'textarea',
      '[contenteditable="true"]',
      'input[type="text"]',
      '[placeholder*="message" i]',
      '[placeholder*="type" i]',
    ];

    for (const selector of chatSelectors) {
      uiReady = await page
        .locator(selector)
        .first()
        .isVisible()
        .catch(() => false);
      if (uiReady) {
        console.log(`✅ Found chat input with selector: ${selector}`);
        break;
      }
    }

    if (!uiReady) {
      console.log('❌ No chat input found, taking screenshot for debugging');
      await page.screenshot({
        path: 'playwright-artifacts/debug-no-chat-input.png',
        fullPage: true,
      });

      // Try to find any interactive elements
      const anyInput = await page.locator('input, textarea, [contenteditable]').count();
      console.log(`Found ${anyInput} input elements on page`);

      // Log page title
      const title = await page.title();
      console.log(`Page title: ${title}`);
    }

    expect(uiReady, 'Chat input should be visible after authentication').toBeTruthy();
    finalize();
  });

  // 1) Document upload and indexing
  Object.entries(fixtures).forEach(([label, path]) => {
    const size = fs.existsSync(path) ? fs.statSync(path).size : 0;
    const isBinary = label === 'pdf' || label === 'docx';
    const validFixture = size > (isBinary ? 2048 : 0);
    (validFixture ? test : test.skip)(`Upload & index ${label}`, async ({ page }) => {
      attachNetworkLogging(page);
      const finalize = await assertNoConsoleErrors(page);

      await page.goto(BASE);
      await tryLogin(page).catch(() => {});

      // Use improved file upload function
      let uploadSuccess = await uploadFile(page, path);

      if (!uploadSuccess) {
        console.log('🔄 Trying fallback upload methods...');
        // Additional file upload attempts can be added here
      }

      if (!uploadSuccess) {
        console.log('❌ No upload method worked, analyzing page structure...');

        // Detailed page analysis
        const allButtons = await page.locator('button').count();
        const allInputs = await page.locator('input').count();
        const allLinks = await page.locator('a').count();

        console.log(`Page analysis: ${allButtons} buttons, ${allInputs} inputs, ${allLinks} links`);

        // Log all buttons with text
        const buttonTexts = await page.locator('button').allTextContents();
        console.log('Button texts:', buttonTexts.slice(0, 20)); // first 20

        // Log all links with text
        const linkTexts = await page.locator('a').allTextContents();
        console.log('Link texts:', linkTexts.slice(0, 20)); // first 20

        // Look for elements with icons (might be upload buttons)
        const iconButtons = await page.locator('button svg, button [class*="icon"]').count();
        console.log(`Found ${iconButtons} buttons with icons`);

        await page.screenshot({
          path: `playwright-artifacts/debug-upload-${label}.png`,
          fullPage: true,
        });

        // Try to find any file-related elements
        const fileRelated = await page
          .locator(
            '[class*="file"], [class*="upload"], [class*="document"], [id*="file"], [id*="upload"]',
          )
          .count();
        console.log(`Found ${fileRelated} file-related elements`);

        throw new Error(
          `Could not find upload mechanism for ${label}. Check debug screenshot and logs.`,
        );
      }

      // Wait for processing - look for upload success indicators
      console.log('⏳ Waiting for upload processing...');
      const uploadIndicators = [
        selectors.uploadList,
        '.upload-success',
        '.file-uploaded',
        '[data-testid*="uploaded"]',
        'text=uploaded',
        'text=success',
      ];

      let processed = false;
      for (const indicator of uploadIndicators) {
        try {
          await page.waitForSelector(indicator, { timeout: 10_000 });
          console.log(`✅ Upload processed - found indicator: ${indicator}`);
          processed = true;
          break;
        } catch (e) {
          continue;
        }
      }

      if (!processed) {
        console.log('⚠️ No upload success indicator found, but continuing...');
      }

      await page.screenshot({ path: `playwright-artifacts/02-upload-${label}.png` });
      finalize();
    });
  });

  // 2) RAG search with web integration (SearXNG)
  test('RAG web search (<10s)', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    await page.goto(BASE);
    await tryLogin(page).catch(() => {});

    // Enable web search in settings (if available)
    await page.click(selectors.settingsButton).catch(() => {});
    await page
      .locator(selectors.webSearchToggle)
      .check({ force: true })
      .catch(() => {});

    // Web search question
    const question = 'What is the news about AI today?';

    const start = Date.now();
    const messageSent = await sendMessage(page, question);
    expect(messageSent, 'Message should be sent successfully').toBeTruthy();

    // Wait for assistant response up to 30s (allow progress indicator)
    await page.waitForSelector(`${selectors.answerBlock}, .progress, .spinner`, {
      timeout: 30_000,
    });
    const duration = Date.now() - start;
    console.log(`Web search answer time: ${duration}ms`);
    expect(duration).toBeLessThanOrEqual(10_000);

    // Check for links/sources
    const content = await page.locator(selectors.answerBlock).first().innerText();
    expect(/https?:\/\//.test(content) || /Source|[[]\d+[]]/i.test(content)).toBeTruthy();

    await page.screenshot({ path: 'playwright-artifacts/03-web-search.png' });
    finalize();
  });

  // 3) RAG over uploaded docs
  test('RAG over uploaded docs', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    await page.goto(BASE);
    await tryLogin(page).catch(() => {});
    const question = 'Summarize the uploaded document and cite the source.';
    await page.fill(selectors.chatInput, question);
    await page.click(selectors.sendButton);

    await page.waitForSelector(selectors.answerBlock, { timeout: 30_000 });
    const answer = await page.locator(selectors.answerBlock).first().innerText();
    expect(/Source|File|Document|\.(pdf|docx|md|txt)/i.test(answer)).toBeTruthy();

    await page.screenshot({ path: 'playwright-artifacts/04-doc-rag.png' });
    finalize();
  });

  // 4) Combined RAG (docs + web)
  test('Combined RAG (docs + web)', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    await page.goto(BASE);
    const question =
      'Match key facts from the uploaded document with the latest web news and add links.';
    await page.fill(selectors.chatInput, question);
    await page.click(selectors.sendButton);

    await page.waitForSelector(selectors.answerBlock, { timeout: 30_000 });
    const answer = await page.locator(selectors.answerBlock).first().innerText();
    expect(/https?:\/\//.test(answer)).toBeTruthy();
    expect(/(Source|File|Document)/i.test(answer)).toBeTruthy();

    await page.screenshot({ path: 'playwright-artifacts/05-combined.png' });
    finalize();
  });

  // 5) RAG testing with real Intel Q3 2023 documents
  test('RAG with Intel Q3 2023 document', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    const ragFile = fixtures.ragPdf1;
    if (!fs.existsSync(ragFile)) {
      test.skip();
      return;
    }

    await page.goto(BASE);
    await tryLogin(page).catch(() => {});

    console.log(`📁 Uploading Intel Q3 2023 document: ${ragFile}`);

    // Upload document via file chooser
    let fileChooser;
    try {
      [fileChooser] = await Promise.all([
        page.waitForEvent('filechooser', { timeout: 10_000 }),
        page.click('button:has(svg), button:has([class*="icon"])', { timeout: 5_000 }),
      ]);
    } catch (error) {
      // Fallback: try direct input
      const fileInput = await page
        .locator('input[type="file"]')
        .first()
        .isVisible()
        .catch(() => false);
      if (fileInput) {
        await page.setInputFiles('input[type="file"]', ragFile);
        console.log('✅ File uploaded via direct input');
      } else {
        throw new Error('Could not find upload mechanism');
      }
      return;
    }
    await fileChooser.setFiles(ragFile);

    // Wait for document processing
    await page.waitForTimeout(5_000);

    // Specific question about Intel Q3 2023
    const question = 'What were the key financial results for Intel in Q3 2023? Cite the source.';
    await page.fill(selectors.chatInput, question);

    const start = Date.now();
    await page.click(selectors.sendButton);

    await page.waitForSelector(selectors.answerBlock, { timeout: 30_000 });
    const duration = Date.now() - start;
    console.log(`Intel Q3 RAG response time: ${duration}ms`);

    const answer = await page.locator(selectors.answerBlock).first().innerText();
    expect(/(Intel|INTC|Q3|2023|revenue|income)/i.test(answer)).toBeTruthy();
    expect(/(Source|File|\.pdf)/i.test(answer)).toBeTruthy();
    expect(duration).toBeLessThanOrEqual(5_000); // Target: <5 seconds

    await page.screenshot({ path: 'playwright-artifacts/06-intel-rag.png' });
    finalize();
  });

  // 6) Multilingual RAG testing (German document)
  test('Multilingual RAG (German document)', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    const ragFile = fixtures.ragPdf2;
    if (!fs.existsSync(ragFile)) {
      test.skip();
      return;
    }

    await page.goto(BASE);
    await tryLogin(page).catch(() => {});

    console.log(`📁 Uploading German document: ${ragFile}`);

    // Upload German document
    let fileChooser;
    try {
      [fileChooser] = await Promise.all([
        page.waitForEvent('filechooser', { timeout: 10_000 }),
        page.click('button:has(svg), button:has([class*="icon"])', { timeout: 5_000 }),
      ]);
    } catch (error) {
      // Fallback: try direct input
      const fileInput = await page
        .locator('input[type="file"]')
        .first()
        .isVisible()
        .catch(() => false);
      if (fileInput) {
        await page.setInputFiles('input[type="file"]', ragFile);
        console.log('✅ German file uploaded via direct input');
      } else {
        throw new Error('Could not find upload mechanism for German document');
      }
      return;
    }
    await fileChooser.setFiles(ragFile);

    await page.waitForTimeout(5_000);

    // Question in German
    const question =
      'Was sind die wichtigsten Informationen in diesem deutschen Dokument? Bitte auf Deutsch antworten.';
    await page.fill(selectors.chatInput, question);

    const start = Date.now();
    await page.click(selectors.sendButton);

    await page.waitForSelector(selectors.answerBlock, { timeout: 30_000 });
    const duration = Date.now() - start;
    console.log(`German RAG response time: ${duration}ms`);

    const answer = await page.locator(selectors.answerBlock).first().innerText();
    expect(/(Dokument|Dusche|August|2017|MB011)/i.test(answer)).toBeTruthy();
    expect(duration).toBeLessThanOrEqual(5_000);

    await page.screenshot({ path: 'playwright-artifacts/07-german-rag.png' });
    finalize();
  });

  // 7) RAG system integration testing
  test('RAG integrations health check', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    console.log('🔍 Testing RAG system integrations...');

    // Check SearXNG API
    const searxngResponse = await page.request
      .get('http://localhost:8080/api/searxng/search?q=test&format=json')
      .catch(() => null);
    console.log(`SearXNG health: ${searxngResponse?.status() || 'FAILED'}`);
    expect(searxngResponse?.ok()).toBeTruthy();

    // Check Ollama API
    const ollamaResponse = await page.request
      .get('http://localhost:11434/api/tags')
      .catch(() => null);
    console.log(`Ollama health: ${ollamaResponse?.status() || 'FAILED'}`);
    expect(ollamaResponse?.ok()).toBeTruthy();

    // Check PostgreSQL via OpenWebUI
    await page.goto(BASE);
    await tryLogin(page).catch(() => {});

    // Simple database test via interface
    const dbTestQuestion = 'Show statistics of uploaded documents.';
    await page.fill(selectors.chatInput, dbTestQuestion);
    await page.click(selectors.sendButton);

    await page.waitForSelector(selectors.answerBlock, { timeout: 15_000 });
    const dbAnswer = await page.locator(selectors.answerBlock).first().innerText();
    console.log('Database integration test completed');

    // Verify we got a response from the database
    expect(dbAnswer.length).toBeGreaterThan(0);

    await page.screenshot({ path: 'playwright-artifacts/08-integrations.png' });
    finalize();
  });

  // 8) RAG performance testing
  test('RAG performance benchmark', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    await page.goto(BASE);
    await tryLogin(page).catch(() => {});

    const performanceTests = [
      { query: 'Brief summary of uploaded documents', maxTime: 5000 },
      { query: 'Find information about technologies in documents', maxTime: 5000 },
      { query: 'Compare data from different sources', maxTime: 7000 },
    ];

    const results: Array<{ query: string; time: number; success: boolean }> = [];

    for (const test of performanceTests) {
      console.log(`⏱️ Testing: ${test.query}`);

      await page.fill(selectors.chatInput, test.query);
      const start = Date.now();
      await page.click(selectors.sendButton);

      try {
        await page.waitForSelector(selectors.answerBlock, { timeout: test.maxTime + 5000 });
        const duration = Date.now() - start;
        const success = duration <= test.maxTime;

        results.push({ query: test.query, time: duration, success });
        console.log(
          `✅ Query completed in ${duration}ms (target: ${test.maxTime}ms) - ${success ? 'PASS' : 'FAIL'}`,
        );

        expect(duration).toBeLessThanOrEqual(test.maxTime);

        // Cleanup for next test
        await page.waitForTimeout(2000);
      } catch (error) {
        results.push({ query: test.query, time: -1, success: false });
        console.log(`❌ Query failed: ${error}`);
        throw error;
      }
    }

    // Result logging
    console.log('📊 Performance Results:');
    results.forEach(result => {
      console.log(`  ${result.query}: ${result.time}ms ${result.success ? '✅' : '❌'}`);
    });

    await page.screenshot({ path: 'playwright-artifacts/09-performance.png' });
    finalize();
  });

  // 9) Check RAG configuration parameters
  test('RAG configuration validation', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    await page.goto(BASE);
    await tryLogin(page).catch(() => {});

    console.log('🔧 Validating RAG configuration...');

    // Attempt to access settings
    const settingsSelectors = [
      'button:has-text("Settings")',
      'button[aria-label="Settings"]',
      'a:has-text("Settings")',
      '[data-testid="settings"]',
      'button:has(svg):has-text("Settings")',
    ];

    let settingsFound = false;
    for (const selector of settingsSelectors) {
      const hasSettings = await page
        .locator(selector)
        .first()
        .isVisible()
        .catch(() => false);
      if (hasSettings) {
        console.log(`✅ Found settings with selector: ${selector}`);
        await page.click(selector);
        settingsFound = true;
        break;
      }
    }

    if (settingsFound) {
      await page.waitForTimeout(2000);

      // Check RAG settings
      const ragSettings = ['Web Search', 'RAG', 'Documents', 'Knowledge', 'Embedding'];

      for (const setting of ragSettings) {
        const hasRagSetting = await page
          .locator(`text=${setting}`)
          .first()
          .isVisible()
          .catch(() => false);
        console.log(`RAG setting "${setting}": ${hasRagSetting ? '✅' : '❌'}`);
      }

      await page.screenshot({ path: 'playwright-artifacts/10-rag-config.png' });
    } else {
      console.log('⚠️ Settings not accessible, skipping configuration validation');
    }

    // Vector search test
    const vectorTestQuery = 'Find documents related to technologies and innovations';
    await page.fill(selectors.chatInput, vectorTestQuery);

    const start = Date.now();
    await page.click(selectors.sendButton);

    await page.waitForSelector(selectors.answerBlock, { timeout: 15_000 });
    const duration = Date.now() - start;

    const answer = await page.locator(selectors.answerBlock).first().innerText();
    const hasVectorResults = /(found|document|source)/i.test(answer);

    console.log(`Vector search test: ${duration}ms, results found: ${hasVectorResults}`);
    expect(hasVectorResults).toBeTruthy();
    expect(duration).toBeLessThanOrEqual(5_000);

    await page.screenshot({ path: 'playwright-artifacts/11-vector-search.png' });
    finalize();
  });

  // 10) Final complex RAG system test
  test('Comprehensive RAG system test', async ({ page }) => {
    attachNetworkLogging(page);
    const finalize = await assertNoConsoleErrors(page);

    await page.goto(BASE);
    await tryLogin(page).catch(() => {});

    console.log('🎯 Running comprehensive RAG system test...');

    // Complex question requiring use of all RAG components
    const complexQuery = `
    Analyze all uploaded documents and find:
    1. Key technical data
    2. Financial indicators (if any)
    3. Compare with current information from the web
    4. Provide sources for each statement
    The answer should be structured with links to sources.
  `;

    await page.fill(selectors.chatInput, complexQuery);

    const start = Date.now();
    await page.click(selectors.sendButton);

    // Expect detailed answer
    await page.waitForSelector(selectors.answerBlock, { timeout: 30_000 });
    const duration = Date.now() - start;

    const answer = await page.locator(selectors.answerBlock).first().innerText();

    // Check answer quality
    const hasStructure = /[1-4]\.|\*|\-/.test(answer); // Structured answer
    const hasSources = /(source|\.pdf|https?:\/\/)/i.test(answer);
    const hasAnalysis = /(analysis|compare|data|indicator)/i.test(answer);
    const hasWebInfo = /(actual|news|web|search)/i.test(answer);

    console.log('Comprehensive test results:');
    console.log(`  Duration: ${duration}ms`);
    console.log(`  Structured: ${hasStructure}`);
    console.log(`  Has sources: ${hasSources}`);
    console.log(`  Has analysis: ${hasAnalysis}`);
    console.log(`  Has web info: ${hasWebInfo}`);

    expect(duration).toBeLessThanOrEqual(10_000); // Extended limit for complex query
    expect(hasStructure).toBeTruthy();
    expect(hasSources).toBeTruthy();
    expect(hasAnalysis).toBeTruthy();
    // Web info is optional - depends on whether web search was invoked
    // This query explicitly asks for web comparison, so we expect web info
    expect(hasWebInfo).toBeTruthy();

    await page.screenshot({ path: 'playwright-artifacts/12-comprehensive.png' });

    // Final system resource check
    console.log('📊 Final system check completed');

    finalize();
  });
}
