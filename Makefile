default: build

SOURCES=src/main.m src/main.c

ifdef DEBUG
CFLAGS+=-g -O0
else
CFLAGS+=-Oz
endif

ifndef SDKROOT
SDKROOT=$(shell xcrun --sdk iphoneos --show-sdk-path)
endif

ifndef TARGET
TARGET=build/app.device
endif

build: check $(TARGET)

$(TARGET): $(SOURCES) tigr/tigr.c tigr/tigr.h Makefile
	clang $(CFLAGS) \
	-isysroot $(SDKROOT) \
	-framework Foundation \
	-framework UIKit \
	-framework QuartzCore \
	-framework OpenGLES \
	-framework GLKit \
	-I tigr \
	-o $@ $(SOURCES) tigr/tigr.c

.PHONY: clean check build

clean:
	rm -rf build/*

check:
	mkdir -p build
	@[ ! -z $(SDKROOT) ] || echo Missing SDKROOT env variable
	@[ ! -z $(TARGET) ] || echo Missing TARGET env variable
