import { expect, test } from '@playwright/test';
import { Buffer } from 'node:buffer';

const isMockMode = process.env.E2E_MOCK_MODE === 'true';

test.describe('Mock OpenWebUI smoke suite', () => {
  test.skip(!isMockMode, 'Mock suite runs only when E2E_MOCK_MODE=true');

  test('displays main interface elements', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('textarea[placeholder*="Message" i]')).toBeVisible();
    await expect(page.getByRole('button', { name: /send/i })).toBeVisible();
    await expect(page.locator('input[type="file"]')).toBeVisible();
  });

  test('toggles web search and sends message', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('textbox').fill('Mock RAG test');
    await page.getByRole('button', { name: /send/i }).click();
    await page.getByRole('checkbox', { name: /web search/i }).check();
    await expect(page.locator('.message-log')).toContainText('Mock RAG test');
    await expect(page.locator('.message-log')).toContainText('Web search enabled');
  });

  test('handles file upload', async ({ page }) => {
    await page.goto('/');
    await page.locator('input[type="file"]').setInputFiles({
      name: 'mock.txt',
      mimeType: 'text/plain',
      buffer: Buffer.from('demo'),
    });
    await expect(page.locator('.message-log')).toContainText('Uploaded 1 file');
  });
});
