//
//  WBViewController.m
//  WBECharts
//
//  Created by WishesBest1986 on 09/04/2017.
//  Copyright (c) 2017 WishesBest1986. All rights reserved.
//

#import "WBViewController.h"
#import <WBECharts/WBECharts.h>
#import "WBTestModel.h"

@interface WBViewController ()

@property (weak, nonatomic) IBOutlet WBEChartsView *echartsView;

@end

@implementation WBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    WBTestModel *model = [WBTestModel new];
    NSString *json = [WBJsonUtils getJsonString:model];
    NSLog(@"%@", json);
    
    _echartsView.theme = WBEChartsThemeDark;
    _echartsView.options = @{@"title" : @{@"text" : @"ECharts入门实例"}, @"tooltip" : @{}, @"legend" : @{@"data" : @[@"销量"]}, @"xAxis" : @{@"data" : @[@"衬衫", @"羊毛衫", @"雪纺衫", @"裤子", @"高跟鞋", @"袜子"]}, @"yAxis" : @{}};
    [_echartsView loadECharts];
    
    [_echartsView showLoadingWithOpts:@{@"text": @"加载中……", @"color": @"#c23531",@"textColor": @"#000", @"maskColor": @"rgba(255, 255, 255, 0.8)", @"zlevel": @0}];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_echartsView hideLoading];
        
        [_echartsView refreshEChartsWithOptions:@{@"series" : @[@{@"name" : @"销量", @"type" : @"bar", @"data" : @[@5, @20, @36, @10, @25, @20]}]}];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
