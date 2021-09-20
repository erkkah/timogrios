#define GLES_SILENCE_DEPRECATION
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include <unistd.h>
#include <os/log.h>
#include "tigr.h"

extern void tigrMain();
extern void tigrIOSInit(int w, int h);

@interface AppDelegate : UIResponder <UIApplicationDelegate, GLKViewDelegate>
@property(strong, nonatomic) UIWindow* window;
@property(strong, nonatomic) EAGLContext* context;
@property(strong, nonatomic) GLKViewController* viewController;
@property(strong, nonatomic) GLKView* view;
@end

@implementation AppDelegate

static NSCondition* renderTime;
static CADisplayLink* displayLink;
static AppDelegate* app;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(id)options {
    app = self;

    CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
    CGSize mainScreenSize = mainScreenBounds.size;
    self.window = [[UIWindow alloc] initWithFrame:mainScreenBounds];

    self.viewController = [[GLKViewController alloc] init];

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    [EAGLContext setCurrentContext:self.context];

    self.view = [[GLKView alloc] initWithFrame:mainScreenBounds context:self.context];
    self.viewController.view = self.view;
    self.view.delegate = self;

    tigrIOSInit(mainScreenSize.width * self.view.contentScaleFactor, mainScreenSize.height * self.view.contentScaleFactor);

    self.window.rootViewController = self.viewController;

    [self.window makeKeyAndVisible];

    renderTime = [[NSCondition alloc] init];

    NSThread* renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(renderMain) object:nil];
    [renderThread start];

    return YES;
}

extern Tigr* currentWindow;
extern void tigrGAPIPresent(Tigr *bmp, int w, int h);

- (void)glkView:(GLKView*)view drawInRect:(CGRect)rect {
    if (currentWindow != 0) {
        CGRect mainScreenBounds = [[UIScreen mainScreen] bounds];
        CGSize size = mainScreenBounds.size;
        float scaleFactor = self.view.contentScaleFactor;
        tigrGAPIPresent(currentWindow, (int)size.width * scaleFactor, (int)size.height * scaleFactor);
    }
    [renderTime signal];
}

- (void)renderMain {
    tigrMain();
}

- (void)pause {
    self.viewController.paused = YES;
}

- (void)resume {
    self.viewController.paused = NO;
}

@end

void ios_swap() {
    [renderTime wait];
}

void ios_acquire_context() {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [app pause];
    });

    [EAGLContext setCurrentContext:app.context];
}

void ios_release_context() {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [EAGLContext setCurrentContext:app.context];
        [app resume];
    });
}

int main(int argc, char* argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
