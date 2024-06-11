SCHEME := BLEMacroApp
SCRIPTS_PATH := Scripts
XCODEBUILD_SCRIPTS_PATH := ${SCRIPTS_PATH}/xcodebuild-scripts

.PHONY: all
all: clean test

Logs:
	mkdir Logs

.PHONY: test
test: test-macOS test-iOS

.PHONY: test-macOS
test-macOS:
	# ====== Test on macOS ======
	cd ./Packages/Package && swift test

.PHONY: test-iOS
test-iOS: Logs
	# ====== Test on iOS ======
	"${XCODEBUILD_SCRIPTS_PATH}/test" "${SCHEME}" "iOS-17-" "iPhone " "Logs/xcodebuild-test-iOS.log" "build/junit-iOS.xml"

.PHONY: clean
clean:
	git clean -fdx
