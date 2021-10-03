#import <UIKit/UIKit.h>

extern Class tigrAppDelegate();

@interface CustomAppDelegate : NSProxy <UIApplicationDelegate>
@property(strong, nonatomic) UIResponder<UIApplicationDelegate>* tigr;
@end

@implementation CustomAppDelegate

- init {
    Class TigrAppDelegate = tigrAppDelegate();
    self.tigr = [[TigrAppDelegate alloc] init];
    return self;
}

- (void)forwardInvocation:(NSInvocation*)invocation {
    [invocation invokeWithTarget:self.tigr];
}

- (BOOL)respondsToSelector:(SEL)selector {
    return [super respondsToSelector:selector] || [self.tigr respondsToSelector:selector];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
    return [self.tigr methodSignatureForSelector:selector];
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id>*)launchOptions {
    // Do custom startup stuff here!
    return [self.tigr application:application didFinishLaunchingWithOptions:launchOptions];
}

@end

int main(int argc, char* argv[]) {
    @autoreleasepool {
        UIApplicationMain(argc, argv, nil, @"CustomAppDelegate");
    }
}
