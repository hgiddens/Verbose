.PHONY: format test

format:
	swift format -ipr .
	npm run format:ts

test:
	swift test
	npx playwright test
