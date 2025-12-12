/**
 * Shared E2E test helpers for ERNI-KI OpenWebUI tests
 *
 * Consolidates common functions used across E2E test files to avoid duplication.
 */

import { expect, type Page, type Request, type Response } from '@playwright/test';
import fs from 'node:fs';

/** Default base URL for tests */
export const BASE_URL = process.env.PW_BASE_URL || 'https://localhost';

/** Check if running in Playwright context */
export const isPlaywrightRunner =
  Boolean(process.env.PLAYWRIGHT_TEST) || Boolean(process.env.PLAYWRIGHT_WORKER_INDEX);

/** Common selectors for OpenWebUI */
export const selectors = {
  fileInput: 'input[type="file"]',
  uploadsTab:
    'button:has-text("Uploads"), button:has-text("Files"), button:has-text("Knowledge"), a:has-text("Uploads")',
  uploadList: '[data-testid="upload-list"], .uploaded-files, .file-list, [class*="upload"]',
  chatInput:
    'textarea[placeholder*="Message"], [role="textbox"], div[contenteditable="true"], textarea',
  settingsButton: 'button[aria-label="Settings"], button:has-text("Settings")',
  webSearchToggle: 'label:has-text("Web Search") input[type="checkbox"], input[name="web_search"]',
  sendButton:
    'button[type="submit"], button:has([class*="send"]), button:has(svg), [aria-label*="Send"], [title*="Send"], button:has-text("Send"), .send-button',
  answerBlock: '.message.assistant, [data-testid="assistant-message"], [class*="message"], .prose',
  attachButton:
    'button[aria-label*="attach"], button[title*="attach"], button:has([class*="paperclip"]), button:has([class*="attach"])',
  uploadButton: 'button[aria-label*="upload"], button[title*="upload"], input[type="file"]',
  plusButton: 'button:has-text("+"), button[aria-label*="add"], button[title*="add"]',
  // Login selectors
  emailInput:
    'input[type="email"], input[name="email"], input#email, input[placeholder*="email" i], input[placeholder*="Email"]',
  passwordInput:
    'input[type="password"], input[name="password"], input#password, input[placeholder*="password" i], input[placeholder*="Password"]',
  submitButton:
    'button:has-text("Sign In"), button[type="submit"], button:has-text("Login"), button:has-text("Continue")',
  loginButtons:
    'button:has-text("Sign In"), button:has-text("Login"), a:has-text("Sign In"), a:has-text("Login")',
};

/**
 * Logging utility with timestamps
 */
export function log(message: string): void {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
}

/**
 * Attempt login to OpenWebUI if login form is present
 * @param page Playwright page
 * @param baseUrl Optional base URL (defaults to BASE_URL)
 * @returns true if login was successful or not required
 */
export async function tryLogin(page: Page, baseUrl: string = BASE_URL): Promise<boolean> {
  log('🔍 Checking for login form...');

  await page.waitForTimeout(2000);

  let hasLogin = await page
    .locator(selectors.emailInput)
    .first()
    .isVisible()
    .catch(() => false);

  log(`Login form visible on main page: ${hasLogin}`);

  if (!hasLogin) {
    // Try to find login button and click it
    const hasLoginButton = await page
      .locator(selectors.loginButtons)
      .first()
      .isVisible()
      .catch(() => false);

    if (hasLoginButton) {
      await page.click(selectors.loginButtons);
      await page.waitForTimeout(1000);
      hasLogin = await page
        .locator(selectors.emailInput)
        .first()
        .isVisible()
        .catch(() => false);
    }

    // Try navigating to /login
    if (!hasLogin) {
      await page.goto(`${baseUrl}/login`).catch(() => {});
      hasLogin = await page
        .locator(selectors.emailInput)
        .first()
        .isVisible()
        .catch(() => false);
    }
  }

  if (!hasLogin) {
    log('❌ No login form found, assuming already authenticated or no auth required');
    return false;
  }

  const EMAIL = process.env.E2E_OPENWEBUI_EMAIL || '';
  const PASS = process.env.E2E_OPENWEBUI_PASSWORD || '';

  if (!EMAIL || !PASS) {
    log('⚠️ Login form detected but E2E_OPENWEBUI_EMAIL/PASSWORD are not set.');
    return false;
  }

  log(`🔑 Attempting login with email: ${EMAIL}`);
  await page.fill(selectors.emailInput, EMAIL);
  await page.fill(selectors.passwordInput, PASS);
  await page
    .click(selectors.submitButton)
    .catch(() => page.press(selectors.passwordInput, 'Enter'));

  try {
    await page.waitForSelector(selectors.chatInput, { timeout: 10_000 });
    log('✅ Login successful - chat input found');
    return true;
  } catch {
    log('❌ Login may have failed - chat input not found');
    return false;
  }
}

/**
 * Attach network request/response logging for debugging
 * @param page Playwright page
 * @param logPath Path to write network log (optional)
 */
export function attachNetworkLogging(page: Page, logPath?: string): void {
  const append = (line: string) => {
    if (logPath) {
      try {
        fs.appendFileSync(logPath, line + '\n');
      } catch {
        // Ignore write errors
      }
    }
  };

  page.on('request', (req: Request) => {
    const url = req.url();
    if (/searxng|ollama|openwebui\/api|docling|tika/i.test(url)) {
      const line = `→ ${req.method()} ${url}`;
      console.log(line);
      append(line);
    }
  });

  page.on('response', (res: Response) => {
    const url = res.url();
    if (/searxng|ollama|openwebui\/api|docling|tika/i.test(url)) {
      const line = `← ${res.status()} ${url}`;
      console.log(line);
      append(line);
    }
  });
}

/**
 * Setup console error tracking and return a finalizer function
 * @param page Playwright page
 * @returns Finalizer function that asserts no console errors occurred
 */
export async function assertNoConsoleErrors(page: Page): Promise<() => void> {
  const errors: string[] = [];

  page.on('console', msg => {
    if (msg.type() === 'error') {
      errors.push(msg.text());
    }
  });

  return () => {
    if (errors.length) {
      console.warn('Console errors:', errors.join('\n'));
    }
    expect(errors.length, 'No console errors').toBe(0);
  };
}

/**
 * Upload a file to OpenWebUI using multiple strategies
 * @param page Playwright page
 * @param filePath Path to file to upload
 * @returns true if upload was successful
 */
export async function uploadFile(page: Page, filePath: string): Promise<boolean> {
  log(`📁 Attempting to upload file: ${filePath}`);

  // Close any open modal windows
  await page.keyboard.press('Escape').catch(() => {});
  await page.waitForTimeout(1000);

  // Strategy 1: Direct input[type="file"]
  const fileInput = await page
    .locator('input[type="file"]')
    .first()
    .isVisible()
    .catch(() => false);

  if (fileInput) {
    await page.setInputFiles('input[type="file"]', filePath);
    log('✅ File uploaded via direct input');
    return true;
  }

  // Strategy 2: OpenWebUI menu sequence
  try {
    const attachButton = page.locator('button:has(img)').first();
    const isAttachVisible = await attachButton.isVisible().catch(() => false);

    if (isAttachVisible) {
      log('🔍 Found attachment button, clicking...');
      await attachButton.click();
      await page.waitForTimeout(1000);

      const uploadMenuItem = page.getByRole('menuitem', { name: 'Upload Files' });
      await uploadMenuItem.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {});
      const isMenuItemVisible = await uploadMenuItem.isVisible().catch(() => false);

      if (isMenuItemVisible) {
        log('🔍 Found "Upload Files" menu item, clicking...');
        const [fileChooser] = await Promise.all([
          page.waitForEvent('filechooser', { timeout: 5000 }),
          uploadMenuItem.click(),
        ]);
        await fileChooser.setFiles(filePath);
        log('✅ File uploaded successfully via OpenWebUI menu');
        await page.waitForTimeout(2000);
        return true;
      }
    }
  } catch (error) {
    log(`❌ OpenWebUI upload method failed: ${error}`);
  }

  // Strategy 3: Hidden file inputs
  try {
    const hiddenFileInputs = await page.locator('input[type="file"]').all();
    log(`Found ${hiddenFileInputs.length} file inputs`);

    for (let i = 0; i < hiddenFileInputs.length; i++) {
      const input = hiddenFileInputs[i];
      if (!input) continue;

      try {
        await input.setInputFiles(filePath);
        log(`✅ File uploaded via hidden input ${i + 1}`);
        await page.waitForTimeout(2000);
        return true;
      } catch {
        continue;
      }
    }
  } catch (error) {
    log(`❌ Hidden input strategy failed: ${error}`);
  }

  // Strategy 4: Icon buttons with file chooser
  try {
    const iconButtons = await page.locator('button:has(svg), button:has([class*="icon"])').all();
    log(`🔍 Found ${iconButtons.length} buttons with icons`);

    for (let i = 0; i < iconButtons.length; i++) {
      const button = iconButtons[i];
      if (!button) continue;

      const isVisible = await button.isVisible().catch(() => false);
      if (!isVisible) continue;

      try {
        await button.click();
        await page.waitForTimeout(500);

        const newFileInput = await page
          .locator('input[type="file"]')
          .first()
          .isVisible()
          .catch(() => false);

        if (newFileInput) {
          await page.setInputFiles('input[type="file"]', filePath);
          log(`✅ Found file input after clicking icon button ${i + 1}`);
          return true;
        }

        // Try file chooser event
        try {
          const fileChooser = await page.waitForEvent('filechooser', { timeout: 1000 });
          await fileChooser.setFiles(filePath);
          log(`✅ File chooser opened after clicking icon button ${i + 1}`);
          return true;
        } catch {
          // Continue to next button
        }
      } catch {
        continue;
      }
    }
  } catch (error) {
    log(`❌ Icon button strategy failed: ${error}`);
  }

  log('❌ All upload strategies failed');
  return false;
}

/**
 * Send a message in the chat
 * @param page Playwright page
 * @param message Message to send
 * @returns true if message was sent
 */
export async function sendMessage(page: Page, message: string): Promise<boolean> {
  log(`💬 Sending message: ${message.substring(0, 50)}...`);

  const inputSelectors = [
    selectors.chatInput,
    'textarea[placeholder*="Message"]',
    'textarea',
    '[role="textbox"]',
    'div[contenteditable="true"]',
  ];

  let inputFound = false;

  for (const selector of inputSelectors) {
    const isVisible = await page
      .locator(selector)
      .first()
      .isVisible()
      .catch(() => false);

    if (isVisible) {
      await page.fill(selector, message);
      inputFound = true;
      log(`✅ Message entered via: ${selector}`);
      break;
    }
  }

  if (!inputFound) {
    log('❌ Could not find chat input');
    return false;
  }

  // Find and click send button
  const sendSelectors = [
    selectors.sendButton,
    'button[type="submit"]',
    'button:has([class*="send"])',
    '[aria-label*="Send"]',
  ];

  for (const selector of sendSelectors) {
    const isVisible = await page
      .locator(selector)
      .first()
      .isVisible()
      .catch(() => false);

    if (isVisible) {
      await page.click(selector);
      log(`✅ Message sent via: ${selector}`);
      return true;
    }
  }

  // Fallback: press Enter
  await page.keyboard.press('Enter');
  log('✅ Message sent via Enter key');
  return true;
}
