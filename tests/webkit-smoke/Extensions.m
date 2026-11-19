// GPL-3.0. Native API feasibility probe, no private APIs or special entitlements.
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface ExtensionProbe : UIResponder <UIApplicationDelegate, WKWebExtensionControllerDelegate, WKWebExtensionTab, WKWebExtensionWindow>
@property (nonatomic, strong) UIWindow *window;
@property WKWebView *webView;
@property WKWebExtensionController *controller;
@property WKWebExtensionContext *context;
@property NSMutableArray *results;
@property NSUInteger ticks;
@property NSInteger version;
@end

@implementation ExtensionProbe
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.results = [NSMutableArray array];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    self.controller = [WKWebExtensionController new];
    self.controller.delegate = self;
    [self probeVersion:2];
    return YES;
}
- (NSArray *)webExtensionController:(WKWebExtensionController *)controller openWindowsForExtensionContext:(WKWebExtensionContext *)context { return @[self]; }
- (NSArray *)tabsForWebExtensionContext:(WKWebExtensionContext *)context { return @[self]; }
- (id<WKWebExtensionTab>)activeTabForWebExtensionContext:(WKWebExtensionContext *)context { return self; }
- (id<WKWebExtensionWindow>)windowForWebExtensionContext:(WKWebExtensionContext *)context { return self; }
- (WKWebView *)webViewForWebExtensionContext:(WKWebExtensionContext *)context { return self.webView; }

- (void)probeVersion:(NSInteger)version {
    self.version = version;
    NSURL *directory = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:[NSString stringWithFormat:@"mv%ld", (long)version]];
    [WKWebExtension extensionWithResourceBaseURL:directory completionHandler:^(WKWebExtension *extension, NSError *error) {
        if (!extension || error || extension.errors.count) {
            [self finish:@{@"stage": @"parse", @"error": error.description ?: extension.errors.description ?: @"nil extension"}];
            return;
        }
        self.context = [[WKWebExtensionContext alloc] initForExtension:extension];
        self.context.uniqueIdentifier = [NSString stringWithFormat:@"reynard-feasibility-mv%ld", (long)version];
        // Test fixtures only: fixed localhost host and storage, NOT a production
        // permission policy or a grant of all requested permissions to user XPIs.
        [self.context setPermissionStatus:WKWebExtensionContextPermissionStatusGrantedExplicitly forPermission:@"storage"];
        [self.context setPermissionStatus:WKWebExtensionContextPermissionStatusGrantedExplicitly forURL:[NSURL URLWithString:@"http://127.0.0.1:8765/one.html"]];
        NSError *loadError = nil;
        if (![self.controller loadExtensionContext:self.context error:&loadError]) {
            [self finish:@{@"stage": @"load", @"error": loadError.description ?: @"load returned NO"}];
            return;
        }
        [self.context loadBackgroundContentWithCompletionHandler:^(NSError *backgroundError) {
            if (backgroundError) {
                [self finish:@{@"stage": @"background", @"error": backgroundError.description}];
                return;
            }
            WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
            configuration.webExtensionController = self.controller;
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
            self.webView = [[WKWebView alloc] initWithFrame:self.window.bounds configuration:configuration];
            [self.window.rootViewController.view addSubview:self.webView];
            [self.controller didOpenWindow:self];
            [self.controller didOpenTab:self];
            [self.controller didActivateTab:self previousActiveTab:nil];
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1:8765/one.html"]]];
            self.ticks = 0;
            [self poll];
        }];
    }];
}
- (void)poll {
    [self.webView evaluateJavaScript:@"document.documentElement.getAttribute('data-extension-result')" completionHandler:^(id value, NSError *error) {
        if ([value isKindOfClass:NSString.class] && [value length]) {
            [self finish:@{@"stage": @"content-message-storage", @"result": value, @"runtimeErrors": [self.context.errors valueForKey:@"description"]}];
        } else if (++self.ticks >= 150) {
            [self finish:@{@"stage": @"timeout", @"error": error.description ?: @"no content-script response", @"runtimeErrors": [self.context.errors valueForKey:@"description"]}];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 5), dispatch_get_main_queue(), ^{ [self poll]; });
        }
    }];
}
- (void)finish:(NSDictionary *)result {
    NSMutableDictionary *entry = result.mutableCopy;
    entry[@"manifestVersion"] = @(self.version);
    [self.results addObject:entry];
    if (self.context) {
        NSError *error = nil;
        BOOL unloaded = [self.controller unloadExtensionContext:self.context error:&error];
        entry[@"unloaded"] = @(unloaded);
        if (error) entry[@"unloadError"] = error.description;
    }
    [self.webView removeFromSuperview];
    self.webView = nil;
    self.context = nil;
    if (self.version == 2) { [self probeVersion:3]; return; }
    NSDictionary *report = @{@"results": self.results, @"scope": @"iOS Simulator native WebExtensions fixture; SideStore/device/uBlock not verified"};
    NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    [data writeToURL:[documents URLByAppendingPathComponent:@"result.json"] atomically:YES];
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(ExtensionProbe.class)); }
}
