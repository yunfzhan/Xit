#import <Cocoa/Cocoa.h>
#import <Webkit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
  Base class for web view controllers, implementing common delegate methods.
**/
@interface XTWebViewController : NSViewController
    <WebFrameLoadDelegate, WebUIDelegate> {
  __weak IBOutlet WebView *_webView;
}

@property (weak) WebView *webView;
@property NSUInteger tabWidth;
@property NSUInteger savedTabWidth;

+ (NSString*)htmlTemplate:(NSString*)name;
+ (NSURL*)baseURL;
+ (NSString*)escapeText:(NSString*)text;

- (void)loadNotice:(NSString*)text;
- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame;

- (id)webActionDelegate;

@end

NS_ASSUME_NONNULL_END
