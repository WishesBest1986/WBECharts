//
//  WBEChartsView.h
//  Pods
//
//  Created by LIJUN on 2017/9/4.
//
//

#import <UIKit/UIKit.h>
#import "WBUtilities.h"

@interface WBEChartsView : UIView

@property (nonatomic, copy) WBEChartsTheme theme;
@property (nonatomic, assign) CGSize divSize;

@property (nonatomic, strong) id options;

- (void)loadECharts;
- (void)refreshEChartsWithOptions:(id)opts;

- (void)showLoading;
- (void)showLoadingWithOpts:(id)opts;
- (void)hideLoading;

- (void)clearECharts;

@end
