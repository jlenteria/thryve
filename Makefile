.DEFAULT_GOAL := help

FLUTTER ?= flutter
DART    ?= dart
ADB     ?= adb

APP_ID    := com.bling.thryve
APK_DEBUG := build/app/outputs/flutter-apk/app-debug.apk
APK       := build/app/outputs/flutter-apk/app-release.apk

.PHONY: help get upgrade outdated format format-check fix analyze test coverage \
        check run run-release build-apk build-apk-release appbundle ios macos web \
        pods clean reset install install-release uninstall

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Setup ────────────────────────────────────────────────────────────

get: ## Install dependencies
	$(FLUTTER) pub get

upgrade: ## Upgrade dependencies within constraints
	$(FLUTTER) pub upgrade

outdated: ## Show newer dependency versions
	$(FLUTTER) pub outdated

# ── Quality (same checks as CI) ──────────────────────────────────────

format: ## Format lib/ and test/
	$(DART) format lib test

format-check: ## Fail if formatting would change anything
	$(DART) format --output=none --set-exit-if-changed lib test

fix: ## Apply automatic lint fixes
	$(DART) fix --apply

analyze: ## Static analysis
	$(FLUTTER) analyze

test: ## Run all tests
	$(FLUTTER) test

coverage: ## Run tests with coverage (coverage/lcov.info)
	$(FLUTTER) test --coverage

check: format-check analyze test ## Everything CI runs, in order

# ── Run ──────────────────────────────────────────────────────────────

run: ## Run on the connected device/emulator
	$(FLUTTER) run

run-release: ## Run a release build on the connected device
	$(FLUTTER) run --release

# ── Build ────────────────────────────────────────────────────────────

build-apk: ## Debug APK
	$(FLUTTER) build apk --debug

build-apk-release: ## Release APK (signed via android/key.properties if present)
	$(FLUTTER) build apk --release

appbundle: ## Release app bundle for Play Store
	$(FLUTTER) build appbundle --release

ios: pods ## iOS release build without codesigning
	$(FLUTTER) build ios --release --no-codesign

macos: pods ## macOS release build
	$(FLUTTER) build macos --release

web: ## Web release build
	$(FLUTTER) build web --release

pods: get ## Install CocoaPods for iOS and macOS
	cd ios && pod install
	cd macos && pod install

# ── Cleanup ──────────────────────────────────────────────────────────

clean: ## Remove build output
	$(FLUTTER) clean

reset: clean get ## Clean, then reinstall dependencies

# ── Device ───────────────────────────────────────────────────────────

install: build-apk ## Build and install the debug APK via adb
	$(ADB) install -r $(APK_DEBUG)

install-release: build-apk-release ## Build and install the release APK via adb
	$(ADB) install -r $(APK)

uninstall: ## Uninstall the app from the connected device
	$(ADB) uninstall $(APP_ID)

