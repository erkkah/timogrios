#import <UIKit/UIKit.h>

extern void tigrInitIOS();

int main(int argc, char* argv[]) {
    tigrInitIOS();

    @autoreleasepool {
        UIApplicationMain(argc, argv, nil, @"TigrAppDelegate");  // NSStringFromClass([AppDelegate class]));
    }
}

