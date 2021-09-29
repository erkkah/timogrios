#import <UIKit/UIKit.h>

extern Class tigrAppDelegate();

int main(int argc, char* argv[]) {
    @autoreleasepool {
        UIApplicationMain(argc, argv, nil, NSStringFromClass(tigrAppDelegate()));
    }
}

