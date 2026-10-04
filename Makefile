.PHONY: build run clean

SDK ?= $(PLAYDATE_SDK_PATH)
ifeq ($(strip $(SDK)),)
SDK := $(shell awk -F '\t' '$$1 == "SDKRoot" { print $$2; exit }' "$(HOME)/.Playdate/config" 2>/dev/null)
endif
ifeq ($(strip $(SDK)),)
$(error Playdate SDK not found; set PLAYDATE_SDK_PATH or configure ~/.Playdate/config)
endif

GAME_NAME := PlaydateStarter
BUILD_DIR := build
GAME_PDX := $(BUILD_DIR)/$(GAME_NAME).pdx
PDC := $(SDK)/bin/pdc
SIMULATOR := $(SDK)/bin/Playdate Simulator.app

build:
	mkdir -p "$(BUILD_DIR)"
	rm -rf "$(GAME_PDX)"
	"$(PDC)" Source "$(GAME_PDX)"

run: build
	open -a "$(SIMULATOR)" "$(GAME_PDX)"

clean:
	rm -rf "$(GAME_PDX)"
