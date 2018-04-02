//
//  RTNetworkConfig.h
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RTBaseRequest;
@class AFSecurityPolicy;

//RTUrlFilterProtocol 接口用于实现对网络请求 URL 或参数的重写，例如可以统一为网络请求加上一些参数，或者修改一些路径。
//例如：我们需要为每个网络请求加上客户端的版本号作为参数时。
@protocol RTUrlFilterProtocol<NSObject>
- (NSString *)filterUrl:(NSString *)originUrl withRequest:(RTBaseRequest *)request;
@end



@interface RTNetworkConfig : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (RTNetworkConfig *)sharedConfig;
@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong, readonly) NSArray<id<RTUrlFilterProtocol>> *urlFilters;

//安全政策将被用于AFNetworking
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;
@property (nonatomic) BOOL debugLogEnabled;

//SessionConfiguration将用于初始化AFHTTPSessionManager。
@property (nonatomic, strong) NSURLSessionConfiguration *sesseionConfiguration;
- (void)addUrlFilter:(id<RTUrlFilterProtocol>)filter;
- (void)clearUrlFilter;


@end

NS_ASSUME_NONNULL_END
