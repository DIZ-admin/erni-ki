// @ts-nocheck
import { test } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const BASE = process.env.PW_BASE_URL || 'https://localhost';

// Skip when Playwright runner is not orchestrating the tests (e.g., `bun test`)
const isPlaywrightRunner =
  Boolean(process.env.PLAYWRIGHT_TEST) || Boolean(process.env.PLAYWRIGHT_WORKER_INDEX);
if (!isPlaywrightRunner) {
  console.warn('Skipping Playwright upload specs outside Playwright runner');
} else {
  // Attempt login
  async function tryLogin(page: any) {
    console.log('🔍 Checking for login form...');

    const emailSel = 'input[type="email"], input[name="email"], input#email';
    const passSel = 'input[type="password"], input[name="password"], input#password';
    const submitSel = 'button:has-text("Sign In"), button[type="submit"]';

    let hasLogin = await page
      .locator(emailSel)
      .first()
      .isVisible()
      .catch(() => false);

    if (!hasLogin) {
      await page.goto(`${BASE}/login`).catch(() => {});
      hasLogin = await page
        .locator(emailSel)
        .first()
        .isVisible()
        .catch(() => false);
      if (!hasLogin) return false;
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

    const chatInput =
      'textarea[placeholder*="Message"], [role="textbox"], div[contenteditable="true"]';
    try {
      await page.waitForSelector(chatInput, { timeout: 10_000 });
      console.log('✅ Login successful - chat input found');
      return true;
    } catch (e) {
      console.log('❌ Login may have failed - chat input not found');
      return false;
    }
  }

  test('Upload file via icon buttons', async ({ page }) => {
    const filePath = 'tests/fixtures/sample.md';
    const fixturesDir = path.dirname(filePath);

    // Create test file if it doesn't exist (race-safe)
    fs.mkdirSync(fixturesDir, { recursive: true });
    try {
      fs.writeFileSync(
        filePath,
        '# Test Document\n\nThis is a test markdown file for upload testing.',
        {
          flag: 'wx',
        },
      );
    } catch (error: any) {
      if (error.code !== 'EEXIST') throw error;
    }

    await page.goto(BASE);

    // Wait for page load
    await page.waitForTimeout(3000);

    // Verify page loaded
    const title = await page.title();
    console.log(`📄 Page title: ${title}`);

    const url = page.url();
    console.log(`🌐 Current URL: ${url}`);

    // Try to login
    const loginSuccess = await tryLogin(page).catch(() => false);
    console.log(`🔐 Login success: ${loginSuccess}`);

    // Wait after login
    await page.waitForTimeout(2000);

    // Check URL after login
    const urlAfterLogin = page.url();
    console.log(`🌐 URL after login: ${urlAfterLogin}`);

    // Close any modal windows
    const modals = await page.locator('[role="dialog"], .modal').count();
    if (modals > 0) {
      console.log(`🔍 Found ${modals} modal(s), trying to close them...`);

      // Try pressing Escape
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);

      // Try clicking close buttons
      const closeButtons = [
        'button:has-text("×")',
        'button:has-text("Close")',
        'button[aria-label="Close"]',
        '.modal button:last-child',
        '[role="dialog"] button:last-child',
      ];

      for (const closeSel of closeButtons) {
        const hasClose = await page
          .locator(closeSel)
          .first()
          .isVisible()
          .catch(() => false);
        if (hasClose) {
          await page.click(closeSel);
          await page.waitForTimeout(500);
          break;
        }
      }
    }

    console.log(`📁 Attempting to upload file: ${filePath}`);

    let uploadSuccess = false;

    // Look for buttons with icons
    const iconButtons = await page.locator('button:has(svg), button:has([class*="icon"])').all();
    console.log(`🔍 Found ${iconButtons.length} buttons with icons, trying each one...`);

    for (let i = 0; i < iconButtons.length; i++) {
      const button = iconButtons[i];
      if (!button) continue;

      const isVisible = await button.isVisible().catch(() => false);
      if (!isVisible) continue;

      console.log(`Trying icon button ${i + 1}/${iconButtons.length}`);

      try {
        // Click on icon button
        await button.click();
        await page.waitForTimeout(500);

        // Check if file input appeared
        const fileInput = await page
          .locator('input[type="file"]')
          .first()
          .isVisible()
          .catch(() => false);
        if (fileInput) {
          console.log(`✅ Found file input after clicking icon button ${i + 1}`);
          await page.setInputFiles('input[type="file"]', filePath);
          uploadSuccess = true;
          break;
        }

        // Check if file chooser opened
        try {
          const fileChooserPromise = page.waitForEvent('filechooser', { timeout: 1000 });
          const fileChooser = await fileChooserPromise;
          if (fileChooser) {
            console.log(`✅ File chooser opened after clicking icon button ${i + 1}`);
            await fileChooser.setFiles(filePath);
            uploadSuccess = true;
            break;
          }
        } catch (e) {
          // File chooser didn't open, continuing
        }
      } catch (e: any) {
        console.log(`❌ Icon button ${i + 1} failed: ${e.message}`);
        continue;
      }
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
      console.log('Button texts:', buttonTexts.slice(0, 20));

      await page.screenshot({
        path: `test-results/debug-upload-failed.png`,
        fullPage: true,
      });

      throw new Error(`Could not find upload mechanism. Check debug screenshot and logs.`);
    }

    console.log('✅ File upload successful!');

    // Wait for file processing
    await page.waitForTimeout(2000);

    await page.screenshot({
      path: `test-results/upload-success.png`,
      fullPage: true,
    });
  });
}
