#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

typedef void (*RSHookMessageExFunc)(Class, SEL, IMP, IMP *);
static NSString * const RSDomain = @"com.rsinsta.preferences";
static NSMutableDictionary<NSString *, NSNumber *> *RSHookAvailable;

static NSArray<NSDictionary *> *RSFeatureList(void) {
    static NSArray *features;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        features = @[
            @{@"key":@"ghost_story_seen", @"title":@"Hide Story Seen", @"group":@"Privacy", @"hook":@YES},
            @{@"key":@"hide_direct_read", @"title":@"Hide Direct Read Receipt", @"group":@"Privacy", @"hook":@YES},
            @{@"key":@"screenshot_bypass", @"title":@"Screenshot Blocking Bypass", @"group":@"Privacy", @"hook":@YES},
            @{@"key":@"deleted_messages", @"title":@"Deleted Messages", @"group":@"Direct"},
            @{@"key":@"view_once", @"title":@"View Once", @"group":@"Direct"},
            @{@"key":@"story_download", @"title":@"Story Download", @"group":@"Stories"},
            @{@"key":@"reels_download", @"title":@"Reels Download", @"group":@"Media"},
            @{@"key":@"photo_download", @"title":@"Photo Download", @"group":@"Media"},
            @{@"key":@"profile_analyzer", @"title":@"Profile Analyzer", @"group":@"Profile"},
            @{@"key":@"profile_photo", @"title":@"Profile Picture Download", @"group":@"Profile"},
            @{@"key":@"comment_search", @"title":@"Comment Search", @"group":@"Profile"},
            @{@"key":@"voice_changer", @"title":@"Voice Changer", @"group":@"Audio"},
            @{@"key":@"call_recording", @"title":@"Call Recording", @"group":@"Audio"},
            @{@"key":@"gemini_ai", @"title":@"Gemini AI", @"group":@"AI"},
            @{@"key":@"auto_reply", @"title":@"AI Auto Reply", @"group":@"AI"},
            @{@"key":@"app_icons", @"title":@"Custom App Icons", @"group":@"Appearance"},
            @{@"key":@"language", @"title":@"Language Settings", @"group":@"Appearance"},
            @{@"key":@"liquid_glass", @"title":@"Liquid Glass", @"group":@"Appearance"},
            @{@"key":@"pip", @"title":@"Picture in Picture", @"group":@"Media"},
            @{@"key":@"reels_blocker", @"title":@"Reels Blocker", @"group":@"Media"},
            @{@"key":@"close_friends", @"title":@"Close Friends", @"group":@"Stories"},
            @{@"key":@"device_identity", @"title":@"Device Identity", @"group":@"Advanced"},
            @{@"key":@"internal_settings", @"title":@"Internal Settings", @"group":@"Advanced"}
        ];
    });
    return features;
}
static NSArray<NSString *> *RSGroups(void) {
    return @[@"Privacy", @"Direct", @"Stories", @"Media", @"Profile", @"Audio", @"AI", @"Appearance", @"Advanced"];
}
static NSArray<NSDictionary *> *RSFeaturesForGroup(NSString *group) {
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *item, NSDictionary *bindings) {
        (void)bindings;
        return [item[@"group"] isEqualToString:group];
    }];
    return [RSFeatureList() filteredArrayUsingPredicate:p];
}
static BOOL RSEnabled(NSString *key) {
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:RSDomain];
    return [prefs[key] boolValue];
}
static void RSSetEnabled(NSString *key, BOOL value) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *prefs = [[defaults persistentDomainForName:RSDomain] mutableCopy] ?: [NSMutableDictionary dictionary];
    prefs[key] = @(value);
    [defaults setPersistentDomain:prefs forName:RSDomain];
}
static UIWindow *RSWindow(void) {
    for (UIWindow *w in UIApplication.sharedApplication.windows) if (w.isKeyWindow) return w;
    return UIApplication.sharedApplication.windows.firstObject;
}
static UIViewController *RSTopController(void) {
    UIViewController *top = RSWindow().rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    return top;
}
static Class RSResolveClass(NSArray<NSString *> *names) {
    for (NSString *name in names) {
        Class cls = NSClassFromString(name);
        if (cls) return cls;
    }
    return Nil;
}
static BOOL RSInstall(Class cls, NSString *selectorName, IMP replacement, IMP *original, BOOL classMethod) {
    if (!cls || !selectorName) return NO;
    if (classMethod) cls = object_getClass(cls);
    SEL selector = NSSelectorFromString(selectorName);
    if (!cls || !class_getInstanceMethod(cls, selector)) return NO;
    RSHookMessageExFunc hook = (RSHookMessageExFunc)dlsym(RTLD_DEFAULT, "MSHookMessageEx");
    if (!hook) return NO;
    hook(cls, selector, replacement, original);
    return YES;
}

// External method signatures are based on static analysis and must be
// validated against the specific Instagram build before enabling.
static void (*RSOrigStorySeen)(id, SEL, id, id, id);
static void RSStorySeen(id obj, SEL cmd, id item, id section, id focused) {
    if (RSEnabled(@"ghost_story_seen")) return;
    if (RSOrigStorySeen) RSOrigStorySeen(obj, cmd, item, section, focused);
}
static BOOL (*RSOrigDirectSeen)(id, SEL);
static BOOL RSDirectSeen(id obj, SEL cmd) {
    if (RSEnabled(@"hide_direct_read")) return NO;
    return RSOrigDirectSeen ? RSOrigDirectSeen(obj, cmd) : YES;
}
static BOOL (*RSOrigScreenBlock)(id, SEL, id);
static BOOL RSScreenBlock(id obj, SEL cmd, id context) {
    if (RSEnabled(@"screenshot_bypass")) return NO;
    return RSOrigScreenBlock ? RSOrigScreenBlock(obj, cmd, context) : YES;
}
static void RSInstallHooks(void) {
    RSHookAvailable = [NSMutableDictionary dictionary];
    Class story = RSResolveClass(@[@"IGStoryViewerItemSeenHandler"]);
    RSHookAvailable[@"ghost_story_seen"] = @(RSInstall(story, @"handleItem:sectionController:focusedModelItem:",
        (IMP)RSStorySeen, (IMP *)&RSOrigStorySeen, NO));
    Class direct = RSResolveClass(@[@"IGDirectThreadViewListAdapterDataSource"]);
    RSHookAvailable[@"hide_direct_read"] = @(RSInstall(direct, @"shouldUpdateLastSeenMessage",
        (IMP)RSDirectSeen, (IMP *)&RSOrigDirectSeen, NO));
    Class screen = RSResolveClass(@[@"IGQuickSnapExperimentationHelper"]);
    RSHookAvailable[@"screenshot_bypass"] = @(RSInstall(screen, @"shouldEnableScreenshotBlocking:",
        (IMP)RSScreenBlock, (IMP *)&RSOrigScreenBlock, YES));
}

@interface RSInstaMenuController : UITableViewController
@end
@implementation RSInstaMenuController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"RS Insta";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self action:@selector(rsDone)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Media URL"
        style:UIBarButtonItemStylePlain target:self action:@selector(rsDownloadURL)];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { (void)tableView; return (NSInteger)RSGroups().count; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView; return RSGroups()[(NSUInteger)section];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; return (NSInteger)RSFeaturesForGroup(RSGroups()[(NSUInteger)section]).count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    NSDictionary *item = RSFeaturesForGroup(RSGroups()[(NSUInteger)ip.section])[(NSUInteger)ip.row];
    NSString *key = item[@"key"];
    BOOL implemented = [item[@"hook"] boolValue];
    BOOL installed = implemented && [RSHookAvailable[key] boolValue];
    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = !implemented ? @"Not implemented" : installed ? @"Experimental hook installed" : @"Hook unavailable";
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    if (installed) {
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.on = RSEnabled(key);
        toggle.accessibilityIdentifier = key;
        [toggle addTarget:self action:@selector(rsToggle:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else {
        cell.textLabel.textColor = UIColor.secondaryLabelColor;
    }
    return cell;
}
- (void)rsToggle:(UISwitch *)toggle { RSSetEnabled(toggle.accessibilityIdentifier, toggle.on); }
- (void)rsDone { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)rsDownloadURL {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Download media URL"
        message:@"Paste a direct HTTPS video or image URL. This does not extract private Instagram media links."
        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"https://example.com/video.mp4";
        field.keyboardType = UIKeyboardTypeURL;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];
    __weak typeof(self) weakSelf = self;
    [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        (void)action;
        NSString *raw = a.textFields.firstObject.text;
        NSURL *url = [NSURL URLWithString:raw ?: @""];
        if (![url.scheme.lowercaseString isEqualToString:@"https"] || !url.host.length) {
            [weakSelf rsMessage:@"Invalid URL" detail:@"Enter a direct HTTPS URL."];
            return;
        }
        NSURLSessionDownloadTask *task = [NSURLSession.sharedSession downloadTaskWithURL:url completionHandler:
            ^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error || !location || ![response isKindOfClass:NSHTTPURLResponse.class] ||
                ((NSHTTPURLResponse *)response).statusCode >= 400) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf rsMessage:@"Download failed" detail:error.localizedDescription ?: @"Request was not successful."];
                });
                return;
            }
            NSString *extension = url.pathExtension.lowercaseString;
            if (![@[@"mp4", @"mov", @"m4v", @"jpg", @"jpeg", @"png", @"webp"] containsObject:extension]) extension = @"bin";
            NSString *name = [NSUUID.UUID.UUIDString stringByAppendingPathExtension:extension];
            NSURL *destination = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:name];
            NSError *moveError = nil;
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:destination error:&moveError];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (moveError) { [weakSelf rsMessage:@"Save failed" detail:moveError.localizedDescription]; return; }
                UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[destination] applicationActivities:nil];
                UIPopoverPresentationController *pop = share.popoverPresentationController;
                if (pop) { pop.barButtonItem = weakSelf.navigationItem.rightBarButtonItem; }
                [weakSelf presentViewController:share animated:YES completion:nil];
            });
        }];
        [task resume];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
- (void)rsMessage:(NSString *)title detail:(NSString *)detail {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:detail
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

@interface RSInstaLauncher : NSObject
@property (nonatomic, strong) UIButton *button;
@end
@implementation RSInstaLauncher
+ (instancetype)shared {
    static RSInstaLauncher *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [self new]; });
    return instance;
}
- (void)openMenu {
    UIViewController *top = RSTopController();
    if (!top || [top isKindOfClass:UINavigationController.class] &&
        [((UINavigationController *)top).topViewController isKindOfClass:RSInstaMenuController.class]) return;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[RSInstaMenuController new]];
    [top presentViewController:nav animated:YES completion:nil];
}
- (void)show {
    UIWindow *window = RSWindow();
    if (!window) return;
    if (self.button.superview != window) {
        [self.button removeFromSuperview];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(MAX(4, window.bounds.size.width - 64), 124, 52, 42);
        button.layer.cornerRadius = 12;
        button.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:0.92];
        [button setTitle:@"RS" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [button addTarget:self action:@selector(openMenu) forControlEvents:UIControlEventTouchUpInside];
        [window addSubview:button];
        self.button = button;
    }
    static const NSInteger gestureTag = 0x525349;
    if (![window viewWithTag:gestureTag]) {
        UIView *marker = [[UIView alloc] initWithFrame:CGRectZero];
        marker.tag = gestureTag;
        [window addSubview:marker];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openMenu)];
        tap.numberOfTouchesRequired = 3;
        tap.numberOfTapsRequired = 1;
        tap.cancelsTouchesInView = NO;
        [window addGestureRecognizer:tap];
    }
}
@end

__attribute__((constructor)) static void RSInstaStartup(void) {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.burbn.instagram"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            RSInstallHooks();
            [[NSNotificationCenter defaultCenter] addObserver:[RSInstaLauncher shared]
                selector:@selector(show) name:UIApplicationDidBecomeActiveNotification object:nil];
            [[RSInstaLauncher shared] show];
        });
    }
}
