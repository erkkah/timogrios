default: check $(TARGET)

SOURCES=src/main.m src/main.c

ifdef DEBUG
CFLAGS+=-g -O0
else
CFLAGS+=-Oz
endif

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

.PHONY: clean check

clean:
	rm -rf build/*

check:
	@[ ! -z $(SDKROOT) ]
