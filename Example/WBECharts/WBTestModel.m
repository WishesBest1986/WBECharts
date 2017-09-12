//
//  WBTestModel.m
//  WBECharts
//
//  Created by LIJUN on 2017/9/12.
//  Copyright © 2017年 WishesBest1986. All rights reserved.
//

#import "WBTestModel.h"

@interface WBTestModel ()

@property (nonatomic, assign) NSInteger internalProp;

@end

@implementation WBTestModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.name = @"nameValue";
        self.internalProp = 1;
    }
    return self;
}

@end
