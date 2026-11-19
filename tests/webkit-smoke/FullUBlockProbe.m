// GPL-3.0. Full uBO prerequisite diagnostic, NOT a uBO implementation.
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface FullUBlockProbe : UIResponder <UIApplicationDelegate, WKWebExtensionControllerDelegate, WKWebExtensionTab, WKWebExtensionWindow>
@property (nonatomic, strong) UIWindow *window;
@property WKWebView *webView;
@property WKWebExtensionController *controller;
@property WKWebExtensionContext *context;
@property NSMutableDictionary *report;
@property BOOL finished;
@property BOOL fetchStarted;
@end

@implementation FullUBlockProbe
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.report = [@{@"scope": @"Full Firefox uBO package parsing and independent native blocking prerequisite test; NOT full uBO execution or browser acceptance", @"officialPackageExecuted": @NO} mutableCopy];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.finished) { self.report[@"timeout"] = @YES; [self finish]; }
    });
    NSURL *package = [NSBundle.mainBundle URLForResource:@"ublock-full" withExtension:@"zip"];
    [WKWebExtension extensionWithResourceBaseURL:package completionHandler:^(WKWebExtension *extension, NSError *error) {
        if (self.finished) return;
        self.report[@"officialPackage"] = @{
            @"name": extension.displayName ?: @"", @"version": extension.version ?: @"",
            @"manifestVersion": @(extension.manifestVersion),
            @"errors": extension ? [extension.errors valueForKey:@"description"] : @[],
            @"fatalError": error.description ?: @"",
            @"parsedPermissions": extension.requestedPermissions.allObjects ?: @[]
        };
        [self startBlockingTest];
    }];
    return YES;
}
- (NSArray *)webExtensionController:(WKWebExtensionController *)controller openWindowsForExtensionContext:(WKWebExtensionContext *)context { return @[self]; }
- (NSArray *)tabsForWebExtensionContext:(WKWebExtensionContext *)context { return @[self]; }
- (id<WKWebExtensionTab>)activeTabForWebExtensionContext:(WKWebExtensionContext *)context { return self; }
- (id<WKWebExtensionWindow>)windowForWebExtensionContext:(WKWebExtensionContext *)context { return self; }
- (WKWebView *)webViewForWebExtensionContext:(WKWebExtensionContext *)context { return self.webView; }

- (void)startBlockingTest {
    NSURL *directory = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"blocking"];
    [WKWebExtension extensionWithResourceBaseURL:directory completionHandler:^(WKWebExtension *extension, NSError *error) {
        if (self.finished) return;
        self.report[@"blockingFixtureParseErrors"] = extension ? [extension.errors valueForKey:@"description"] : @[];
        if (!extension || error) { self.report[@"fatalError"] = error.description ?: @"nil fixture"; [self finish]; return; }
        // Diagnostic only: retain parse warnings and try loading so that a
        // recognized event cannot be mistaken for working blocking semantics.
        WKWebExtensionControllerConfiguration *host = [WKWebExtensionControllerConfiguration configurationWithIdentifier:NSUUID.UUID];
        host.defaultWebsiteDataStore = WKWebsiteDataStore.defaultDataStore;
        self.controller = [[WKWebExtensionController alloc] initWithConfiguration:host];
        self.controller.delegate = self;
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        configuration.websiteDataStore = WKWebsiteDataStore.defaultDataStore;
        configuration.webExtensionController = self.controller;
        self.webView = [[WKWebView alloc] initWithFrame:self.window.bounds configuration:configuration];
        [self.window.rootViewController.view addSubview:self.webView];
        [self.controller didOpenWindow:self];
        [self.controller didOpenTab:self];
        [self.controller didFocusWindow:self];
        [self.controller didActivateTab:self previousActiveTab:nil];
        self.context = [[WKWebExtensionContext alloc] initForExtension:extension];
        self.context.uniqueIdentifier = NSUUID.UUID.UUIDString;
        for (NSString *permission in @[@"storage", @"webRequest", @"webRequestBlocking"]) {
            [self.context setPermissionStatus:WKWebExtensionContextPermissionStatusGrantedExplicitly forPermission:permission];
        }
        for (WKWebExtensionMatchPattern *pattern in extension.requestedPermissionMatchPatterns) {
            [self.context setPermissionStatus:WKWebExtensionContextPermissionStatusGrantedExplicitly forMatchPattern:pattern];
        }
        NSError *loadError = nil;
        if (![self.controller loadExtensionContext:self.context error:&loadError]) {
            self.report[@"fatalError"] = loadError.description ?: @"load returned NO";
            [self finish]; return;
        }
        [self.context loadBackgroundContentWithCompletionHandler:^(NSError *backgroundError) {
            if (self.finished) return;
            if (backgroundError) { self.report[@"fatalError"] = backgroundError.description; [self finish]; return; }
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1:8765/one.html"]]];
            [self poll];
        }];
    }];
}
- (void)poll {
    if (self.finished) return;
    [self.webView evaluateJavaScript:@"({capabilities:document.documentElement.getAttribute('data-blocking-capabilities'),fetch:document.documentElement.getAttribute('data-blocking-fetch')})" completionHandler:^(id value, NSError *error) {
        if (self.finished) return;
        NSDictionary *result = [value isKindOfClass:NSDictionary.class] ? value : nil;
        NSString *capabilities = [result[@"capabilities"] isKindOfClass:NSString.class] ? result[@"capabilities"] : nil;
        NSString *fetch = [result[@"fetch"] isKindOfClass:NSString.class] ? result[@"fetch"] : nil;
        if (capabilities && !self.fetchStarted) {
            self.fetchStarted = YES;
            // Page-world requests, not extension-origin fetches which can be
            // exempt from webRequest interception. Unique URLs defeat caches.
            NSString *script = @"void (async()=>{const token=Date.now(); const out={}; for(const name of ['control','blocked']) { try { const r=await fetch('/'+name+'.txt?probe='+token,{cache:'no-store'}); out[name]={loaded:true,status:r.status,body:await r.text()}; } catch(e) {out[name]={loaded:false,error:String(e)};} } document.documentElement.setAttribute('data-blocking-fetch',JSON.stringify(out)); window.postMessage('reynard-blocking-refresh','*'); })()";
            [self.webView evaluateJavaScript:script completionHandler:^(id ignored, NSError *fetchError) {
                if (fetchError) self.report[@"fetchScriptError"] = fetchError.description;
            }];
        }
        if (fetch && capabilities) {
            NSDictionary *network = [NSJSONSerialization JSONObjectWithData:[fetch dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            NSDictionary *api = [NSJSONSerialization JSONObjectWithData:[capabilities dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            // Wait for the content-world post-fetch capability readback too.
            if ([api[@"afterFetch"] boolValue]) {
                self.report[@"network"] = network ?: @{};
                self.report[@"capabilities"] = api ?: @{};
                self.report[@"blockingHonored"] = @([network[@"control"][@"loaded"] boolValue] && ![network[@"blocked"][@"loaded"] boolValue] && [api[@"blockedRequestsObserved"] integerValue] > 0);
                [self finish]; return;
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 5), dispatch_get_main_queue(), ^{ [self poll]; });
    }];
}
- (void)finish {
    if (self.finished) return;
    self.finished = YES;
    if (self.context) {
        self.report[@"runtimeErrors"] = [self.context.errors valueForKey:@"description"];
        NSError *error = nil;
        self.report[@"unloaded"] = @([self.controller unloadExtensionContext:self.context error:&error]);
        if (error) self.report[@"unloadError"] = error.description;
    }
    self.report[@"fullUBlockOriginVerified"] = @NO;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.report options:NSJSONWritingPrettyPrinted error:nil];
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    [data writeToURL:[documents URLByAppendingPathComponent:@"result.json"] atomically:YES];
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(FullUBlockProbe.class)); }
}
