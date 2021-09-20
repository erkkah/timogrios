default: app

SDKROOT:=$(shell xcrun --sdk iphonesimulator --show-sdk-path)
#SDKROOT:=$(shell xcrun --sdk iphoneos --show-sdk-path)

defines:
	clang -isysroot $(SDKROOT) -dM -E - < /dev/null

app: main.m main.c tigr/tigr.c tigr/tigr.h MakeTest.app
	clang -isysroot $(SDKROOT) \
	-framework Foundation \
	-framework UIKit \
	-framework QuartzCore \
	-framework OpenGLES \
	-framework GLKit \
	-I tigr \
	-o MakeTest.app/$@ main.m main.c tigr/tigr.c

.PHONY: clean

MakeTest.app:
	mkdir MakeTest.app

clean:
	rm MakeTest.app/app
