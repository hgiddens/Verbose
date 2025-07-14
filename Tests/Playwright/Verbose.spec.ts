import { test, expect } from '@playwright/test';
import { VerbosePage } from './pages/VerbosePage';

test('redirects to /en by default language page', async ({ page }) => {
    const verbosePage = new VerbosePage(page);
    await verbosePage.goto();
    
    await expect(page).toHaveURL('/en');
    await expect(verbosePage.appTitle).toBeVisible();
});

test('redirects to /de with appropriate accept-language header', async ({ browser }) => {
    const context = await browser.newContext({
        locale: 'de-DE',
        extraHTTPHeaders: {
            'Accept-Language': 'de-DE,de;q=0.9,en;q=0.8'
        }
    });
    const page = await context.newPage();
    const verbosePage = new VerbosePage(page);
    await verbosePage.goto();
    
    await expect(page).toHaveURL('/de');
    await expect(verbosePage.appTitle).toBeVisible();
    await expect(verbosePage.germanPlaceholder).toBeVisible();
});

test('switching languages by tapping the link works', async ({ page }) => {
    const verbosePage = new VerbosePage(page);
    await verbosePage.gotoEnglish();
    
    await verbosePage.switchToGerman();
    await expect(page).toHaveURL('/de');
    await expect(verbosePage.germanPlaceholder).toBeVisible();
    
    await verbosePage.switchToEnglish();
    await expect(page).toHaveURL('/en');
    await expect(verbosePage.englishPlaceholder).toBeVisible();
});

test('pattern search returns expected specific words', async ({ page }) => {
    const verbosePage = new VerbosePage(page);
    await verbosePage.gotoEnglish();
    
    await verbosePage.submitPattern('v?r?o?e');
    
    await expect(verbosePage.resultsHeading).toBeVisible();
    await expect(verbosePage.wordList.getByText('variole')).toBeVisible();
    await expect(verbosePage.wordList.getByText('verbose')).toBeVisible();
});

test('clicking word link opens Wiktionary in new tab', async ({ page, context }) => {
    const verbosePage = new VerbosePage(page);
    await verbosePage.gotoEnglish();
    
    await verbosePage.submitPattern('verbose');
    
    await expect(verbosePage.resultsHeading).toBeVisible();
    
    const pagePromise = context.waitForEvent('page');
    await verbosePage.firstWordLink.click();
    const newPage = await pagePromise;
    await newPage.waitForLoadState();
    
    await expect(newPage).toHaveURL(/^https:\/\/en\.(m\.)?wiktionary\.org\/wiki\/verbose$/);
    
    await newPage.close();
});

test('submitting a pattern with no matches works', async ({ page }) => {
    const verbosePage = new VerbosePage(page);
    await verbosePage.gotoEnglish();
    
    // Fill in a pattern that should have no matches
    await verbosePage.submitPattern('zzzzz?zzzzz');
    
    await expect(verbosePage.noResultsHeading).toBeVisible();
    await expect(verbosePage.wordListItems).toHaveCount(0);
});

test('submitting a malicious pattern is handled safely', async ({ page }) => {
    // Set up dialog listener before any actions that might trigger it
    page.on('dialog', async dialog => {
        throw new Error('Alert should not be triggered');
    });
    
    const verbosePage = new VerbosePage(page);
    await verbosePage.gotoEnglish();
    
    await verbosePage.submitPattern("<script>alert('hi')</script>");
    
    await expect(verbosePage.errorHeading).toBeVisible();
    await expect(page.getByText('<script>alert(\'hi\')</script>')).toBeVisible();
});
