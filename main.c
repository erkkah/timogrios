#include "tigr.h"

void tigrMain() {
    Tigr* screen = tigrWindow(320, 200, "Hello", TIGR_2X);
    const char* message = "Hello, world.";
    int textHeight = tigrTextHeight(tfont, message);
    int textWidth = tigrTextWidth(tfont, message);

    while (!tigrClosed(screen)) {
        tigrClear(screen, tigrRGB(0x80, 0x90, 0xa0));

        int textX = (screen->w - textWidth) / 2;
        int textY = (screen->h - textHeight) / 2;

        tigrPrint(screen, tfont, textX, textY, tigrRGB(0xff, 0xff, 0xff), message);
        tigrUpdate(screen);
    }
    tigrFree(screen);
}
