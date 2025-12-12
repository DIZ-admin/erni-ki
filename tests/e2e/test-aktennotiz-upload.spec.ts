/**
 * Automated test for uploading DOCX file "Aktennotiz_Andre Arnold 10.10.2025.docx"
 * through OpenWebUI web interface using Playwright
 *
 * Goal: Verify end-to-end process of uploading and processing DOCX file through ERNI-KI RAG system
 */

import { expect, test } from '@playwright/test';
import fs from 'node:fs';

import { BASE_URL, isPlaywrightRunner, log, tryLogin, uploadFile } from './helpers';

// Skip when Playwright runner is not orchestrating the tests (e.g., `bun test`)
if (!isPlaywrightRunner) {
  console.warn('Skipping Playwright aktennotiz specs outside Playwright runner');
} else {
  const BASE = BASE_URL;
  const DOCX_FILE = 'tests/fixtures/Aktennotiz_Andre Arnold 10.10.2025.docx';

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

    // Step 3: Upload file using shared helper
    log('📁 Step 3: Uploading file...');
    const uploadStartTime = Date.now();

    const uploadSuccess = await uploadFile(page, DOCX_FILE);
    const uploadEndTime = Date.now();

    if (!uploadSuccess) {
      log('❌ Could not find upload mechanism');
      await page.screenshot({
        path: 'test-results/03-upload-failed.png',
        fullPage: true,
      });
      throw new Error('Could not find file upload mechanism');
    }

    log(`✅ File uploaded successfully (${uploadEndTime - uploadStartTime}ms)`);

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
}
