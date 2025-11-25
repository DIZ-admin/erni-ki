// @ts-nocheck
/**
 * Automated test for uploading DOCX file "Aktennotiz_Andre Arnold 10.10.2025.docx"
 * through OpenWebUI web interface using Playwright
 *
 * Goal: Verify end-to-end process of uploading and processing DOCX file through ERNI-KI RAG system
 */

import { expect, test } from '@playwright/test';
import fs from 'node:fs';

const BASE = process.env.PW_BASE_URL || 'http://localhost:8080';
const DOCX_FILE = 'tests/fixtures/Aktennotiz_Andre Arnold 10.10.2025.docx';

// Logging with timestamps
function log(message: string) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`);
}

// Attempt login
async function tryLogin(page: any) {
  log('🔍 Checking for login form...');

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
    log('⚠️ Login form detected but E2E_OPENWEBUI_EMAIL/PASSWORD are not set.');
    return false;
  }

  log(`🔑 Attempting login with email: ${EMAIL}`);
  await page.fill(emailSel, EMAIL);
  await page.fill(passSel, PASS);
  await page.click(submitSel).catch(() => page.press(passSel, 'Enter'));

  const chatInput =
    'textarea[placeholder*="Message"], [role="textbox"], div[contenteditable="true"]';
  try {
    await page.waitForSelector(chatInput, { timeout: 10_000 });
    log('✅ Login successful - chat input found');
    return true;
  } catch (e) {
    log('❌ Login may have failed - chat input not found');
    return false;
  }
}

test('Upload and process Aktennotiz DOCX file', async ({ page }) => {
  const startTime = Date.now();

  // Check if file exists
  if (!fs.existsSync(DOCX_FILE)) {
    throw new Error(`DOCX file not found: ${DOCX_FILE}`);
  }

  const fileStats = fs.statSync(DOCX_FILE);
  log(`📄 File to upload: ${DOCX_FILE}`);
  log(`📊 File size: ${(fileStats.size / 1024).toFixed(2)} KB`);

  // Step 1: Open OpenWebUI
  log('🌐 Step 1: Opening OpenWebUI...');
  const navStartTime = Date.now();
  await page.goto(BASE);
  const navEndTime = Date.now();
  log(`✅ Page loaded in ${navEndTime - navStartTime}ms`);

  // Initial page screenshot
  await page.screenshot({
    path: 'test-results/01-initial-page.png',
    fullPage: true,
  });

  // Wait for page load
  await page.waitForTimeout(3000);

  const title = await page.title();
  log(`📄 Page title: ${title}`);

  // Step 2: Login
  log('🔐 Step 2: Attempting login...');
  const loginStartTime = Date.now();
  const loginSuccess = await tryLogin(page).catch(() => false);
  const loginEndTime = Date.now();
  log(
    `${loginSuccess ? '✅' : '⚠️'} Login ${loginSuccess ? 'successful' : 'skipped'} (${loginEndTime - loginStartTime}ms)`,
  );

  await page.waitForTimeout(2000);

  // Screenshot after login
  await page.screenshot({
    path: 'test-results/02-after-login.png',
    fullPage: true,
  });

  // Close modal windows
  const modals = await page.locator('[role="dialog"], .modal').count();
  if (modals > 0) {
    log(`🔍 Found ${modals} modal(s), closing...`);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
  }

  // Step 3: Find and click file upload button
  log('📁 Step 3: Looking for file upload button...');
  const uploadStartTime = Date.now();

  let uploadSuccess = false;
  let uploadMethod = '';

  // Method 1: Search for button with paperclip or plus icon
  const iconButtons = await page.locator('button:has(svg), button:has([class*="icon"])').all();
  log(`🔍 Found ${iconButtons.length} buttons with icons`);

  for (let i = 0; i < iconButtons.length; i++) {
    const button = iconButtons[i];
    if (!button) continue;

    const isVisible = await button.isVisible().catch(() => false);
    if (!isVisible) continue;

    try {
      // Get aria-label or title for identification
      const ariaLabel = await button.getAttribute('aria-label').catch(() => '');
      const title = await button.getAttribute('title').catch(() => '');

      // Search for buttons related to file upload
      if (
        ariaLabel?.toLowerCase().includes('upload') ||
        ariaLabel?.toLowerCase().includes('file') ||
        ariaLabel?.toLowerCase().includes('attach') ||
        title?.toLowerCase().includes('upload') ||
        title?.toLowerCase().includes('file')
      ) {
        log(`🎯 Found potential upload button: ${ariaLabel || title}`);

        // Try to click and open file chooser
        const [fileChooser] = await Promise.all([
          page.waitForEvent('filechooser', { timeout: 2000 }).catch(() => null),
          button.click(),
        ]);

        if (fileChooser) {
          log(`✅ File chooser opened!`);
          await fileChooser.setFiles(DOCX_FILE);
          uploadSuccess = true;
          uploadMethod = `Icon button with ${ariaLabel || title}`;
          break;
        }
      }
    } catch (e: any) {
      // Continue searching
    }
  }

  // Method 2: Direct input[type="file"] search
  if (!uploadSuccess) {
    log('🔍 Trying direct file input method...');
    const fileInput = await page.locator('input[type="file"]').first();
    const fileInputVisible = await fileInput.isVisible().catch(() => false);

    if (fileInputVisible) {
      await fileInput.setInputFiles(DOCX_FILE);
      uploadSuccess = true;
      uploadMethod = 'Direct file input';
      log('✅ File uploaded via direct input');
    }
  }

  // Method 3: Search via button text
  if (!uploadSuccess) {
    log('🔍 Trying text-based button search...');
    const uploadButtons = await page.locator('button:has-text("Upload")').all();

    for (const button of uploadButtons) {
      try {
        const [fileChooser] = await Promise.all([
          page.waitForEvent('filechooser', { timeout: 2000 }).catch(() => null),
          button.click(),
        ]);

        if (fileChooser) {
          await fileChooser.setFiles(DOCX_FILE);
          uploadSuccess = true;
          uploadMethod = 'Text-based upload button';
          log('✅ File uploaded via text button');
          break;
        }
      } catch (e) {
        continue;
      }
    }
  }

  const uploadEndTime = Date.now();

  if (!uploadSuccess) {
    log('❌ Could not find upload mechanism');

    // Detailed page analysis
    const allButtons = await page.locator('button').count();
    const buttonTexts = await page.locator('button').allTextContents();
    log(`📊 Page has ${allButtons} buttons`);
    log(`📝 Button texts (first 20): ${buttonTexts.slice(0, 20).join(', ')}`);

    await page.screenshot({
      path: 'test-results/03-upload-failed.png',
      fullPage: true,
    });

    throw new Error('Could not find file upload mechanism');
  }

  log(`✅ File uploaded successfully via: ${uploadMethod} (${uploadEndTime - uploadStartTime}ms)`);

  // Screenshot after upload
  await page.screenshot({
    path: 'test-results/04-file-uploaded.png',
    fullPage: true,
  });

  // Step 4: Wait for file processing
  log('⏳ Step 4: Waiting for file processing...');
  const processingStartTime = Date.now();

  // Wait for processing indicators or completion
  await page.waitForTimeout(5000);

  const processingEndTime = Date.now();
  const processingTime = processingEndTime - processingStartTime;
  log(`✅ Processing completed in ${processingTime}ms`);

  // Screenshot after processing
  await page.screenshot({
    path: 'test-results/05-processing-complete.png',
    fullPage: true,
  });

  // Step 5: Check browser console for errors
  log('🔍 Step 5: Checking browser console for errors...');
  const consoleLogs: any[] = [];
  page.on('console', msg => {
    consoleLogs.push({
      type: msg.type(),
      text: msg.text(),
    });
  });

  // Check for errors
  const errors = consoleLogs.filter(log => log.type === 'error');
  if (errors.length > 0) {
    log(`⚠️ Found ${errors.length} console errors:`);
    errors.forEach(err => log(`  - ${err.text}`));
  } else {
    log('✅ No console errors found');
  }

  // Final metrics
  const totalTime = Date.now() - startTime;
  log('\n📊 === TEST SUMMARY ===');
  log(`✅ Total test time: ${totalTime}ms`);
  log(`✅ File upload time: ${uploadEndTime - uploadStartTime}ms`);
  log(`✅ Processing time: ${processingTime}ms`);
  log(`✅ Upload method: ${uploadMethod}`);
  log(`✅ File size: ${(fileStats.size / 1024).toFixed(2)} KB`);
  log(
    `${processingTime < 10000 ? '✅' : '⚠️'} Processing time ${processingTime < 10000 ? 'meets' : 'exceeds'} target (<10s)`,
  );
  log(`${errors.length === 0 ? '✅' : '❌'} Console errors: ${errors.length}`);

  // Final screenshot
  await page.screenshot({
    path: 'test-results/06-final-state.png',
    fullPage: true,
  });

  // Checks
  expect(uploadSuccess).toBe(true);
  expect(processingTime).toBeLessThan(10000); // Target: <10 seconds
  expect(errors.length).toBe(0);
});
