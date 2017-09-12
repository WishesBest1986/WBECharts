//
//  WBJsonUtils.h
//  Pods
//
//  Created by LIJUN on 2017/9/11.
//
//

#import <Foundation/Foundation.h>

@interface WBJsonUtils : NSObject

+ (NSString *)getJsonString:(id)obj;

+ (NSData *)getJsonData:(id)obj;

+ (NSDictionary *)getObjectData:(id)obj;

@end
