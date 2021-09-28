default: check $(TARGET)

builtins:
	clang -isysroot $(SDKROOT) -dM -E - < /dev/null

check:
	@[ ! -z $(SDKROOT) ]

SOURCES=main.m main.c

$(TARGET): $(SOURCES) tigr/tigr.c tigr/tigr.h
	clang -isysroot $(SDKROOT) \
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
