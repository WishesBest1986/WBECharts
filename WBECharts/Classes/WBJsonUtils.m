//
//  WBJsonUtils.m
//  Pods
//
//  Created by LIJUN on 2017/9/11.
//
//

#import "WBJsonUtils.h"
#import <objc/runtime.h>

@implementation WBJsonUtils

#pragma mark - Private Static Method

+ (NSString *)jsonStringWithPrettyPrint:(BOOL)prettyPrint dict:(NSDictionary *)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:(NSJSONWritingOptions)(prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"jsonStringWithPrettyPrint: error:%@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

+ (NSData *)getJson:(id)obj options:(NSJSONWritingOptions)options
{
    return [self getJson:obj options:options error:nil];
}

+ (NSData *)getJson:(id)obj options:(NSJSONWritingOptions)options error:(NSError **)error
{
    return [NSJSONSerialization dataWithJSONObject:[self getObjectData:obj] options:options error:error];
}

+ (id)getObjectInternal:(id)obj
{
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSArray *objArr = obj;
        NSMutableArray *arr = [NSMutableArray array];
        for (int i = 0; i < objArr.count; i ++) {
            [arr setObject:[self getObjectInternal:objArr[i]] atIndexedSubscript:i];
        }
        return arr;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *objDict = obj;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSString *key in objDict.allKeys) {
            [dict setObject:[self getObjectInternal:objDict[key]] forKey:key];
        }
        return dict;
    }
    
    return [self getObjectData:obj];
}

#pragma mark - Public Static Method

+ (NSString *)getJsonString:(id)obj
{
    NSString *jsonString;
    NSData *jsonData;
    if ([obj isKindOfClass:[NSArray class]]) {
        NSString *tmpJson;
        jsonString = @"[";
        for (id object in obj) {
            tmpJson = [self getJsonString:object];
            jsonString = [NSString stringWithFormat:@"%@%@,", jsonString, tmpJson];
        }
        jsonString = [[jsonString substringToIndex:jsonString.length - 1] stringByAppendingString:@"]"];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        jsonString = [self jsonStringWithPrettyPrint:YES dict:obj];
    } else {
        jsonData = [self getJsonData:obj];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

+ (NSData *)getJsonData:(id)obj
{
    return [self getJson:obj options:NSJSONWritingPrettyPrinted];
}

+ (NSDictionary *)getObjectData:(id)obj
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    unsigned int propsCount;
    Class cls = [obj class];
    do {
        objc_property_t *props = class_copyPropertyList(cls, &propsCount);
        for (int i = 0; i < propsCount; i ++) {
            objc_property_t prop = props[i];
            
            NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
            id value = [obj valueForKey:propName];
            if (value == nil) {
//                value = [NSNull null];
                continue;
            } else {
                value = [self getObjectInternal:value];
            }
            [dict setObject:value forKey:propName];
        }
        free(props);
        cls = [cls superclass];
    } while (cls != [NSObject class]);
    return dict;
}

@end
