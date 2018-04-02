//
//  RTNetworkConfig.m
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "RTNetworkConfig.h"
#import "RTBaseRequest.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif


@implementation RTNetworkConfig{
    NSMutableArray <id<RTUrlFilterProtocol>> *_urlFilters;
}

+ (RTNetworkConfig *)sharedConfig{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init{
    if (self = [super init]) {
        _baseUrl = @"";
        _urlFilters = [NSMutableArray array];
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
        _debugLogEnabled = NO;
    }
    return self;
}

- (void)addUrlFilter:(id<RTUrlFilterProtocol>)filter{
    [_urlFilters addObject:filter];
}

- (void)clearUrlFilter{
    [_urlFilters removeAllObjects];
}


- (NSArray<id<RTUrlFilterProtocol>> *)urlFilters{
    return [_urlFilters copy];
}



#pragma mark ---NSObject
- (NSString *)description{
    return [NSString stringWithFormat:@"<%@: %p>{ baseURL: %@}",NSStringFromClass([self class]),self,self.baseUrl];
}




@end
