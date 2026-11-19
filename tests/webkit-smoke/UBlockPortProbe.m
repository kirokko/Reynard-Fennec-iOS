// SPDX-License-Identifier: GPL-3.0-or-later
// Native execution of an unofficial FULL-uBO port. No private API or Gecko.
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface UBlockPortProbe : UIResponder <UIApplicationDelegate, WKWebExtensionControllerDelegate, WKWebExtensionTab, WKWebExtensionWindow, WKNavigationDelegate>
@property (nonatomic, strong) UIWindow *window;
@property WKWebView *webView;
@property WKWebView *popup;
@property WKWebExtensionController *controller;
@property WKWebExtensionContext *context;
@property NSMutableDictionary *report;
@property NSString *phase;
@property BOOL finished;
@property BOOL fetchStarted;
@property BOOL updateStarted;
@property BOOL updatedFetchStarted;
@property NSUInteger popupTicks;
@end
@implementation UBlockPortProbe
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.report = [@{@"scope": @"Unofficial full-uBO source port: DNR network backend, upstream startup/content/popup probes. Not a production browser or full compatibility acceptance.", @"fullUBlockOriginVerified": @NO} mutableCopy];
    self.phase = @"parse";
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!self.finished) { self.report[@"timeoutPhase"] = self.phase; [self finish]; }
    });
    NSURL *directory = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"ubo"];
    [WKWebExtension extensionWithResourceBaseURL:directory completionHandler:^(WKWebExtension *extension, NSError *error) {
        if (self.finished) return;
        self.report[@"parseErrors"] = extension ? [extension.errors valueForKey:@"description"] : @[];
        self.report[@"parsedVersion"] = extension.version ?: @"";
        self.report[@"parsedPermissions"] = extension.requestedPermissions.allObjects ?: @[];
        if (!extension || error || extension.errors.count) {
            self.report[@"fatalError"] = error.description ?: @"Extension parse errors"; [self finish]; return;
        }
        WKWebExtensionControllerConfiguration *host = [WKWebExtensionControllerConfiguration configurationWithIdentifier:NSUUID.UUID];
        host.defaultWebsiteDataStore = WKWebsiteDataStore.defaultDataStore;
        self.controller = [[WKWebExtensionController alloc] initWithConfiguration:host];
        self.controller.delegate = self;
        self.webView = [[WKWebView alloc] initWithFrame:self.window.bounds configuration:[self webConfiguration]];
        self.webView.navigationDelegate = self;
        [self.window.rootViewController.view addSubview:self.webView];
        [self.controller didOpenWindow:self]; [self.controller didOpenTab:self];
        [self.controller didFocusWindow:self]; [self.controller didActivateTab:self previousActiveTab:nil];
        self.context = [[WKWebExtensionContext alloc] initForExtension:extension];
        self.context.uniqueIdentifier = NSUUID.UUID.UUIDString; // Fresh disposable test profile.
        // Trusted, pinned CI bundle ONLY. Not a production user-XPI permission policy.
        for (NSString *permission in extension.requestedPermissions) {
            [self.context setPermissionStatus:WKWebExtensionContextPermissionStatusGrantedExplicitly forPermission:permission];
        }
        for (WKWebExtensionMatchPattern *pattern in extension.requestedPermissionMatchPatterns) {
            [self.context setPermissionStatus:WKWebExtensionContextPermissionStatusGrantedExplicitly forMatchPattern:pattern];
        }
        NSError *loadError = nil;
        self.phase = @"load";
        if (![self.controller loadExtensionContext:self.context error:&loadError]) {
            self.report[@"fatalError"] = loadError.description ?: @"Native context load failed"; [self finish]; return;
        }
        self.phase = @"background";
        [self.context loadBackgroundContentWithCompletionHandler:^(NSError *backgroundError) {
            if (self.finished) return;
            if (backgroundError) { self.report[@"fatalError"] = backgroundError.description; [self finish]; return; }
            self.phase = @"page-network-content";
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://127.0.0.1:8765/port/index.html"]]];
            [self poll];
        }];
    }];
    return YES;
}
- (WKWebViewConfiguration *)webConfiguration {
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.websiteDataStore = WKWebsiteDataStore.defaultDataStore;
    configuration.webExtensionController = self.controller;
    return configuration;
}
- (NSArray *)webExtensionController:(WKWebExtensionController *)controller openWindowsForExtensionContext:(WKWebExtensionContext *)context { return @[self]; }
- (NSArray *)tabsForWebExtensionContext:(WKWebExtensionContext *)context { return @[self]; }
- (id<WKWebExtensionTab>)activeTabForWebExtensionContext:(WKWebExtensionContext *)context { return self; }
- (id<WKWebExtensionWindow>)windowForWebExtensionContext:(WKWebExtensionContext *)context { return self; }
- (WKWebView *)webViewForWebExtensionContext:(WKWebExtensionContext *)context { return self.webView; }
- (NSURL *)urlForWebExtensionContext:(WKWebExtensionContext *)context { return self.webView.URL; }
- (NSString *)titleForWebExtensionContext:(WKWebExtensionContext *)context { return self.webView.title; }
- (BOOL)isActiveForWebExtensionContext:(WKWebExtensionContext *)context { return YES; }

- (void)poll {
    if (self.finished) return;
    NSString *read = @"(()=>{const e=document.documentElement;return {status:e.getAttribute('data-ubo-port-status'),transaction:e.getAttribute('data-ubo-port-transaction'),fetch:e.getAttribute('data-ubo-port-fetch'),update:e.getAttribute('data-ubo-port-update'),updatedFetch:e.getAttribute('data-ubo-port-updated-fetch'),bridgeError:e.getAttribute('data-ubo-port-bridge-error'),cosmetic:document.querySelector('.port-ad')?getComputedStyle(document.querySelector('.port-ad')).display:'missing',scriptlet:window.__reynardScriptlet===true};})()";
    [self.webView evaluateJavaScript:read completionHandler:^(id value, NSError *error) {
        if (self.finished) return;
        if (![value isKindOfClass:NSDictionary.class]) { [self later]; return; }
        NSDictionary *state = value;
        if ([state[@"bridgeError"] isKindOfClass:NSString.class]) self.report[@"bridgeError"] = state[@"bridgeError"];
        NSDictionary *status = [self json:state[@"status"]];
        if (status) self.report[@"port"] = status;
        NSString *networkStage = status[@"network"][@"stage"];
        if ([networkStage isEqual:@"failed"]) { self.report[@"fatalError"] = @"Port network setup failed"; [self finish]; return; }
        NSString *upstreamStage = status[@"upstream"][@"stage"];
        BOOL upstreamSettled = [@[@"ready", @"failed", @"initialization-timeout"] containsObject:upstreamStage ?: @""];
        if ([networkStage isEqual:@"installed"] && upstreamSettled && !self.fetchStarted) {
            self.fetchStarted = YES;
            NSString *script = @"void(async()=>{const token=Date.now();const out={};for(const name of ['control','blocked','allowed','important','xhr-only','image-only','new-rule']){try{const r=await fetch('/port/'+name+'.txt?token='+token,{cache:'no-store'});out[name]={loaded:true,status:r.status,body:(await r.text()).slice(0,128)};}catch(e){out[name]={loaded:false,error:String(e)}}}for(const name of ['control.png','image-only.txt']){out['image:'+name]=await new Promise(resolve=>{const img=new Image();const t=setTimeout(()=>resolve({timeout:true}),5000);img.onload=()=>{clearTimeout(t);resolve({loaded:true})};img.onerror=()=>{clearTimeout(t);resolve({loaded:false})};img.src='/port/'+name+'?image='+token;});}document.documentElement.setAttribute('data-ubo-port-fetch',JSON.stringify(out));})()";
            [self.webView evaluateJavaScript:script completionHandler:^(id ignored, NSError *scriptError) {
                if (scriptError) self.report[@"fetchScriptError"] = scriptError.description;
            }];
        }
        NSDictionary *fetch = [self json:state[@"fetch"]];
        NSDictionary *transaction = [self json:state[@"transaction"]];
        if (fetch && transaction && !self.updateStarted) {
            self.report[@"network"] = fetch; self.report[@"transaction"] = transaction;
            self.report[@"content"] = @{@"cosmeticDisplay":state[@"cosmetic"] ?: @"", @"scriptletObserved":state[@"scriptlet"] ?: @NO};
            self.updateStarted = YES;
            [self.webView evaluateJavaScript:@"window.postMessage('reynard-port-update','*')" completionHandler:nil];
        }
        NSDictionary *update = [self json:state[@"update"]];
        if (update && !self.updatedFetchStarted) {
            self.report[@"update"] = update; self.updatedFetchStarted = YES;
            [self.webView evaluateJavaScript:@"void fetch('/port/new-rule.txt?after-update='+Date.now(),{cache:'no-store'}).then(async r=>({loaded:true,status:r.status,body:await r.text()})).catch(e=>({loaded:false,error:String(e)})).then(r=>document.documentElement.setAttribute('data-ubo-port-updated-fetch',JSON.stringify(r)))" completionHandler:nil];
        }
        NSDictionary *updated = [self json:state[@"updatedFetch"]];
        if (updated) {
            self.report[@"updatedFetch"] = updated; [self probePopup]; return;
        }
        [self later];
    }];
}
- (NSDictionary *)json:(id)value {
    if (![value isKindOfClass:NSString.class]) return nil;
    id result = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    return [result isKindOfClass:NSDictionary.class] ? result : nil;
}
- (void)later { dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/5), dispatch_get_main_queue(), ^{ [self poll]; }); }
- (void)probePopup {
    self.phase = @"original-popup";
    WKWebViewConfiguration *configuration = self.context.webViewConfiguration;
    if (!configuration) { self.report[@"popupError"] = @"No extension-owned webViewConfiguration"; [self finish]; return; }
    WKUserScript *errors = [[WKUserScript alloc] initWithSource:@"window.__portUIErrors=[];addEventListener('error',e=>window.__portUIErrors.push(String(e.error||e.message)));addEventListener('unhandledrejection',e=>window.__portUIErrors.push(String(e.reason)))" injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:errors];
    self.popup = [[WKWebView alloc] initWithFrame:self.window.bounds configuration:configuration];
    self.popup.navigationDelegate = self;
    [self.window.rootViewController.view addSubview:self.popup];
    [self.popup loadRequest:[NSURLRequest requestWithURL:[self.context.baseURL URLByAppendingPathComponent:@"popup-fenix.html"]]];
    [self pollPopup];
}
- (void)pollPopup {
    if (self.finished) return;
    [self.popup evaluateJavaScript:@"({url:location.href,version:document.querySelector('#version')?.textContent||'',hostname:document.querySelector('#hostname')?.textContent||'',hasOriginalSwitch:!!document.querySelector('#switch'),bodyClass:document.body.className,errors:window.__portUIErrors||[]})" completionHandler:^(id value, NSError *error) {
        if (self.finished) return;
        if ([value isKindOfClass:NSDictionary.class]) self.report[@"originalPopup"] = value;
        if (([value isKindOfClass:NSDictionary.class] && [value[@"version"] containsString:@"1.76.4"]) || ++self.popupTicks >= 50) {
            [self.popup takeSnapshotWithConfiguration:nil completionHandler:^(UIImage *image, NSError *snapshotError) {
                NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
                if (image) [UIImagePNGRepresentation(image) writeToURL:[documents URLByAppendingPathComponent:@"popup.png"] atomically:YES];
                if (snapshotError) self.report[@"snapshotError"] = snapshotError.description;
                [self finish];
            }];
        } else dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC/5), dispatch_get_main_queue(), ^{ [self pollPopup]; });
    }];
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.report[webView == self.popup ? @"popupNavigationError" : @"pageNavigationError"] = error.description;
}
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webView:webView didFailProvisionalNavigation:navigation withError:error];
}
- (void)finish {
    if (self.finished) return;
    self.finished = YES;
    self.report[@"finalPhase"] = self.phase;
    if (self.context) {
        self.report[@"runtimeErrors"] = [self.context.errors valueForKey:@"description"];
        NSError *error = nil;
        self.report[@"unloaded"] = @([self.controller unloadExtensionContext:self.context error:&error]);
        if (error) self.report[@"unloadError"] = error.description;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.report options:NSJSONWritingPrettyPrinted error:nil];
    NSURL *documents = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    [data writeToURL:[documents URLByAppendingPathComponent:@"result.json"] atomically:YES];
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(UBlockPortProbe.class)); }
}
