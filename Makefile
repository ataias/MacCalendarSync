SOURCES = $(wildcard Sources/**/*.swift)
TESTS = $(wildcard Tests/**/*.swift)
BUILD = $(shell swift build --show-bin-path -c release)
DBUILD = $(shell swift build --show-bin-path -c debug)
TARGET=MacCalendarSync
RELEASE_BIN = $(BUILD)/$(TARGET)
DEBUG_BIN = $(DBUILD)/$(TARGET)
PREFIX=~/.local/bin/

.PHONY: all
all: $(RELEASE_BIN)

.PHONY: debug
debug: $(DEBUG_BIN)

$(RELEASE_BIN): $(SOURCES)
	@echo $(RELEASE_BIN)
	swift build -c release

$(DEBUG_BIN): $(SOURCES)
	@echo $(DEBUG_BIN)
	swift build

.PHONY: run-debug
run-debug: $(DEBUG_BIN)
	$(DEBUG_BIN)

.PHONY: run
run: $(RELEASE_BIN)
	$(RELEASE_BIN)

.PHONY: clean
clean:
	rm -f $(RELEASE_BIN)
	rm -f $(DEBUG_BIN)


.PHONY: uninstall
uninstall: $(PREFIX)/$(TARGET)
	rm $(PREFIX)/$(TARGET)

.PHONY: install
install: $(RELEASE_BIN)
	cp $(RELEASE_BIN) $(PREFIX)
