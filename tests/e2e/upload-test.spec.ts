import { test } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

import { BASE_URL, isPlaywrightRunner, tryLogin, uploadFile } from './helpers';

// Skip when Playwright runner is not orchestrating the tests (e.g., `bun test`)
if (!isPlaywrightRunner) {
  console.warn('Skipping Playwright upload specs outside Playwright runner');
} else {
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

    await page.goto(BASE_URL);

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

    // Use shared upload function
    const uploadSuccess = await uploadFile(page, filePath);

    if (!uploadSuccess) {
      await page.screenshot({
        path: 'test-results/debug-upload-failed.png',
        fullPage: true,
      });
      throw new Error('Could not find upload mechanism. Check debug screenshot and logs.');
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
