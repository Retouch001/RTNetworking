//
//  RTNetworkAgent.h
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RTBaseRequest;

@interface RTNetworkAgent : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (RTNetworkAgent *)sharedAgent;

/*
 1.创建一个Task并开启任务(resume)
 2.将该Task保存到一个名为_requestsRecord的字典中
 */
- (void)addRequest:(RTBaseRequest *)request;



/*
 1.取消Task的请求
 2.将该Task从_requestsRecord中移除
 */
- (void)cancelRequest:(RTBaseRequest *)request;
- (void)cancelAllRequests;


/*
 1.拼接出一个完整的域名字符串(RTBaseRequest的子类中、RTNetworkConfig中、遵循RTUrlFilterProtocol的协议的类中来判断拼接)
 */
- (NSString *)buildRequestUrl:(RTBaseRequest *)request;

@end

NS_ASSUME_NONNULL_END
