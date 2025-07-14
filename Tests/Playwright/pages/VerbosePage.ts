import { type Locator, type Page } from '@playwright/test';

export class VerbosePage {
  readonly page: Page;

  // Main page elements
  readonly appTitle: Locator;
  readonly patternInput: Locator;
  readonly submitButton: Locator;

  // Language switching
  readonly germanLanguageLink: Locator;
  readonly englishLanguageLink: Locator;

  // Placeholder text (language-specific)
  readonly englishPlaceholder: Locator;
  readonly germanPlaceholder: Locator;

  // Results section
  readonly resultsHeading: Locator;
  readonly noResultsHeading: Locator;
  readonly errorHeading: Locator;
  readonly wordList: Locator;
  readonly wordListItems: Locator;
  readonly firstWordLink: Locator;

  constructor(page: Page) {
    this.page = page;

    // Main page elements
    this.appTitle = page.getByRole('heading', { name: 'Verbose' });
    this.patternInput = page.locator('#pattern');
    this.submitButton = page.getByRole('button', { name: "Let's go!" });

    // Language switching
    this.germanLanguageLink = page.getByRole('link', { name: 'Deutsch' });
    this.englishLanguageLink = page.getByRole('link', { name: 'English' });

    // Placeholder text
    this.englishPlaceholder = page.getByPlaceholder('v?r?o?e');
    this.germanPlaceholder = page.getByPlaceholder('Stra?e');

    // Results section
    this.resultsHeading = page.getByRole('heading', { name: 'Words:' });
    this.noResultsHeading = page.getByRole('heading', {
      name: 'No words found :(',
    });
    this.errorHeading = page.getByRole('heading', { name: 'Sorry!' });
    this.wordList = page.locator('.word-list');
    this.wordListItems = page.locator('.word-list ul li');
    this.firstWordLink = page.locator('.word-list ul li a').first();
  }

  // Navigation methods
  async goto(path: string = '/') {
    await this.page.goto(path);
  }

  async gotoEnglish() {
    await this.page.goto('/en');
  }

  async gotoGerman() {
    await this.page.goto('/de');
  }

  // Interaction methods
  async submitPattern(pattern: string) {
    await this.patternInput.fill(pattern);
    await this.submitButton.click();
  }

  async switchToGerman() {
    await this.germanLanguageLink.click();
  }

  async switchToEnglish() {
    await this.englishLanguageLink.click();
  }

  // Utility methods
  async getWordCount(): Promise<number> {
    return await this.wordListItems.count();
  }

  async getFirstWordLinkHref(): Promise<string | null> {
    return await this.firstWordLink.getAttribute('href');
  }

  // Assertion helpers
  async expectToBeOnEnglishPage() {
    await this.page.waitForURL('/en');
    await this.englishPlaceholder.waitFor({ state: 'visible' });
  }

  async expectToBeOnGermanPage() {
    await this.page.waitForURL('/de');
    await this.germanPlaceholder.waitFor({ state: 'visible' });
  }

  async expectResultsToBeVisible() {
    await this.resultsHeading.waitFor({ state: 'visible' });
  }

  async expectNoResults() {
    await this.noResultsHeading.waitFor({ state: 'visible' });
  }

  async expectError() {
    await this.errorHeading.waitFor({ state: 'visible' });
  }
}
