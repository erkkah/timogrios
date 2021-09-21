#include <errno.h>
#include "tigr.h"

void tigrMain() {
    Tigr* screen = tigrWindow(320, 200, "Hello", TIGR_2X);
    const char* message = "Hello, world.";
    int textHeight = tigrTextHeight(tfont, message);
    int textWidth = tigrTextWidth(tfont, message);

    Tigr* logo = tigrLoadImage("timogr.png");
    if (!logo) {
        tigrError(0, "Failed to load image: %d", errno);
    }

    while (!tigrClosed(screen)) {
        int numTouches = 0;
        
        tigrClear(screen, tigrRGB(0x80, 0x90, 0xa0));

        int logoX = (screen->w - logo->w) / 2;
        tigrBlitAlpha(screen, logo, logoX, 10, 0, 0, logo->w, logo->h, numTouches > 0 ? 0.5 : 1);

        int textX = (screen->w - textWidth) / 2;
        int textY = (screen->h - textHeight) / 2;

        tigrPrint(screen, tfont, textX, textY, tigrRGB(0xff, 0xff, 0xff), message);
        tigrUpdate(screen);
    }
    tigrFree(screen);
}
