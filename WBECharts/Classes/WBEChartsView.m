//
//  WBEChartsView.m
//  Pods
//
//  Created by LIJUN on 2017/9/4.
//
//

#import "WBEChartsView.h"
#import <WebKit/WebKit.h>
#import "WBJsonUtils.h"

@interface WBEChartsView () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, copy) NSString *webContent;
@property (nonatomic, copy) NSString *webBundlePath;

@property (nonatomic, assign) BOOL isChartsRenderFinished;
@property (nonatomic, strong) NSMutableArray *tryAfterRenderJSArray;

@end

@implementation WBEChartsView

#pragma mark - Init & Dealloc

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self.webView.configuration.userContentController removeAllUserScripts];
}

#pragma mark - Public Method

- (void)loadECharts
{
    [_webView loadHTMLString:self.webContent baseURL:[NSURL fileURLWithPath:self.webBundlePath]];
}

- (void)refreshEChartsWithOptions:(id)opts
{
    NSString *optsJson = [WBJsonUtils getJsonString:opts];
    [self callJsMethods:[NSString stringWithFormat:@"refreshEChart(%@)", optsJson]];
}

- (void)showLoading
{
    [self callJsMethods:@"myChart.showLoading()"];
}

- (void)showLoadingWithOpts:(id)opts
{
    NSString *optsJson = [WBJsonUtils getJsonString:opts];
    [self callJsMethods:[NSString stringWithFormat:@"myChart.showLoading('default', %@)", optsJson]];
}

- (void)hideLoading
{
    [self callJsMethods:@"myChart.hideLoading()"];
}

- (void)clearECharts
{
    [self callJsMethods:@"myChart.clear()"];
}

#pragma mark - Override Method

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSLog(@"...... %.2f", self.webView.estimatedProgress);
    }
}

#pragma mark - Private Method

- (void)commonInit
{
    self.backgroundColor = [UIColor clearColor];
    
    self.webView = [[WKWebView alloc] initWithFrame:self.bounds];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.scrollView.bounces = NO;
    _webView.scrollView.scrollEnabled = NO;
    _webView.opaque = NO;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    [self addSubview:_webView];
    
    WKUserContentController *userContentController = self.webView.configuration.userContentController;
    
    // Disable magnification in WKWebView.
    NSString *fitJS = @"var meta = document.createElement('meta');"
    "meta.setAttribute('name', 'viewport');"
    "meta.setAttribute('content', 'width=device-width');"
    "var head = document.getElementsByTagName('head')[0];"
    "head.appendChild(meta);";
    NSArray *fitUserScripts = [userContentController.userScripts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.source = %@", fitJS]];
    if (0 == fitUserScripts.count) {
        WKUserScript *fitUserScript = [[WKUserScript alloc] initWithSource:fitJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
        [userContentController addUserScript:fitUserScript];
    }
    
    // Disable callouts in WKWebView.
    NSString *calloutJS = @"var style = document.createElement('style');"
    "style.type = 'text/css';"
    "style.innerText = '*:not(input):not(textarea) {-webkit-user-select: none; -webkit-touch-callout: none;}';"
    "var head = document.getElementsByTagName('head')[0];"
    "head.appendChild(style)";
    NSArray *calloutScripts = [userContentController.userScripts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.source = %@", calloutJS]];
    if (0 == calloutScripts.count) {
        WKUserScript *calloutScript = [[WKUserScript alloc] initWithSource:calloutJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
        [userContentController addUserScript:calloutScript];
    }
    
    NSArray *allFrameworks = [[NSBundle mainBundle] pathsForResourcesOfType:@"framework" inDirectory:@"Frameworks"];
    
    NSBundle *echartsBundle = [NSBundle mainBundle];
    for (NSString *path in allFrameworks) {
        if ([path hasSuffix:@"WBECharts.framework"]) {
            NSString *dirPath = [path stringByAppendingString:@"/WBECharts.bundle"];
            echartsBundle = [NSBundle bundleWithPath:dirPath];
            break;
        }
    }
    self.webBundlePath = [echartsBundle bundlePath];
    
    NSString *urlStr = [echartsBundle pathForResource:@"echarts" ofType:@"html"];
    NSString *content = [[NSString alloc] initWithContentsOfFile:urlStr encoding:NSUTF8StringEncoding error:nil];
    self.webContent = content;
    
    self.isChartsRenderFinished = NO;
    self.tryAfterRenderJSArray = [NSMutableArray array];
}

- (void)callJsMethods:(NSString *)methodWithParam
{
    __weak __typeof(self) weakSelf = self;
    [self.webView evaluateJavaScript:methodWithParam completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        __typeof(self) strongSelf = weakSelf;
        if (error) {
            if (!strongSelf.isChartsRenderFinished) {
                [strongSelf.tryAfterRenderJSArray addObject:methodWithParam];
            } else {
                NSLog(@"%@", error);
            }
        }
    }];
}

- (void)resizeDiv
{
    CGFloat height = self.frame.size.height;
    CGFloat width = self.frame.size.width;
    if (!CGSizeEqualToSize(self.divSize, CGSizeZero)) {
        height = self.divSize.height;
        width = self.divSize.width;
    } else {
        self.divSize = CGSizeMake(width, height);
    }
    
    NSString *divSizeCss = [NSString stringWithFormat:@"'height:%.0fpx;width:%.0fpx;'", height, width];
    NSString *js = [NSString stringWithFormat:@"%@(%@)", @"resizeDiv", divSizeCss];
    [self callJsMethods:js];
}

#pragma mark - WKNavigationDelegate Method

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    __weak __typeof(self) weakSelf = self;
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        __typeof(self) strongSelf = weakSelf;
        if ([response isEqualToString:@"complete"]) {
            strongSelf.isChartsRenderFinished = YES;
            [strongSelf resizeDiv];

            if (self.options == nil) {
                [strongSelf callJsMethods:[NSString stringWithFormat:@"initEChartView('%@')", strongSelf.theme]];
            } else {
                NSString *optsJson = [WBJsonUtils getJsonString:strongSelf.options];
                [strongSelf callJsMethods:[NSString stringWithFormat:@"loadEChart(%@, '%@')", optsJson, strongSelf.theme]];
            }
            
            if (strongSelf.tryAfterRenderJSArray.count > 0) {
                NSMutableArray *retriedJSArray = [NSMutableArray array];
                for (NSString *js in strongSelf.tryAfterRenderJSArray) {
                    [strongSelf callJsMethods:js];
                    [retriedJSArray addObject:js];
                }
                [strongSelf.tryAfterRenderJSArray removeObjectsInArray:retriedJSArray];
            }
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!strongSelf.isChartsRenderFinished) {
                    [strongSelf loadECharts];
                }
            });
        }
    }];
}

#pragma mark - WKUIDelegate Method

//- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
//{
////    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JS调用alert" message:message preferredStyle:UIAlertControllerStyleAlert];
////    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
////        completionHandler();
////    }]];
////    [self presentViewController:alert animated:YES completion:NULL];
//}
//
//- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
//{
////    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JS调用confirm" message:message preferredStyle:UIAlertControllerStyleAlert];
////    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
////        completionHandler(YES);
////    }]];
////    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
////        completionHandler(NO);
////    }]];
////    [self presentViewController:alert animated:YES completion:NULL];
//}
//
//- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
//{
////    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JS调用输入框" message:prompt preferredStyle:UIAlertControllerStyleAlert];
////    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
////        textField.textColor = [UIColor redColor];
////        textField.placeholder = defaultText;
////    }];
////    
////    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
////        completionHandler([[alert.textFields lastObject] text]);
////    }]];
////    
////    [self presentViewController:alert animated:YES completion:NULL];
//}

#pragma mark - WKScriptMessageHandler Method

//- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
//{
//    
//}

@end
