//
//  RTBaseRequest.h
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const RTRequestValidationErrorDomain;

NS_ENUM(NSInteger){
    RTRequestValidationErrorInvalidStatusCode = -8,
    RTRequestValidationErrorInvalidJSONFormat = -9
};


// HTTP请求方式
typedef NS_ENUM(NSInteger, RTRequestMethod){
    RTRequestMethodGET = 0,
    RTRequestMethodPOST,
    RTRequestMethodHEAD,
    RTRequestMethodPUT,
    RTRequestMethodDELETE,
    RTRequestMethodPATCH
};

// 请求序列化器类型
typedef NS_ENUM(NSInteger, RTRequestSerializerType){
    RTRequestSerializerTypeHTTP = 0,
    RTRequestSerializerTypeJSON
};

//响应序列化类型
typedef NS_ENUM(NSInteger, RTResponseSerializerType){
    /// NSData type
    RTResponseSerializerTypeHTTP,
    /// JSON object type
    RTResponseSerializerTypeJSON,
    /// NSXMLParser type
    RTResponseSerializerTypeXMLParser,
};


// 请求优先权
typedef NS_ENUM(NSInteger, RTRequestPriority){
    RTRequestPriorityLow = -4L,
    RTRequestPriorityDefault = 0,
    RTRequestPriorityHigh = 4,
};


@protocol AFMultipartFormData;
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);
@class RTBaseRequest;
typedef void(^RTRequestCompletionBlock)(__kindof RTBaseRequest *request);

@protocol RTRequestDelegate<NSObject>
@optional
- (void)requestFinished:(__kindof RTBaseRequest *)request;
- (void)requestFailed:(__kindof RTBaseRequest *)request;
@end



//定义了几种可用于跟踪请求状态的可选方法。符合此协议的对象可以相应地执行其他配置。
@protocol RTRequestAccessory<NSObject>
@optional
- (void)requestWillStart:(id)request;
- (void)requestWillStop:(id)request;
- (void)requestDidStop:(id)request;
@end




@interface RTBaseRequest : NSObject

@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readonly) NSURLRequest *currentRequest;
@property (nonatomic, strong, readonly) NSURLRequest *originalRequest;
@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSInteger responseStatusCode;
@property (nonatomic, strong, readonly, nullable) NSDictionary *responseHeaders;
@property (nonatomic, strong, readonly, nullable) NSData *responseData;
@property (nonatomic, strong, readonly, nullable) NSString *responseString;
@property (nonatomic, strong, readonly, nullable) id responseObject;
@property (nonatomic, strong, readonly, nullable) id responseJSONObject;
@property (nonatomic, strong, readonly, nullable) NSError *error;
@property (nonatomic, readonly, getter=isCancelled) BOOL cancelled;
@property (nonatomic, readonly, getter=isExecuting) BOOL executing;
@property (nonatomic) NSInteger tag;
@property (nonatomic, strong, nullable) NSDictionary *userInfo;


@property (nonatomic, weak, nullable) id<RTRequestDelegate> delegate;
@property (nonatomic, copy, nullable) RTRequestCompletionBlock successCompletionBlock;
@property (nonatomic, copy, nullable) RTRequestCompletionBlock failureCompletionBlock;
@property (nonatomic, strong, nullable) NSMutableArray<id<RTRequestAccessory>> *requestAccessories;
@property (nonatomic, strong, nullable) AFConstructingBlock constructingBodyBlock;
@property (nonatomic) RTRequestPriority requestPriority;


- (void)setCompletionBlockWithSuccess:(nullable RTRequestCompletionBlock)success failure:(nullable RTRequestCompletionBlock)failure;
- (void)clearCompletionBlock;
- (void)addAccessory:(id<RTRequestAccessory>)accessory;
- (void)start;
- (void)stop;



- (NSString *)baseUrl;
- (NSString *)requestUrl;
- (NSTimeInterval)requestTimeoutInterval;
- (nullable id)requestArgument;
- (RTRequestMethod)requestMethod;
- (RTRequestSerializerType)requestSerializerType;
- (RTResponseSerializerType)responseSerializerType;



//是否允许使用蜂窝式无线电(如果存在)。默认是肯定的。
- (BOOL)allowsCellularAccess;

//检验返回的数据有效性
- (nullable id)jsonValidator;
- (BOOL)statusCodeValidator;


@end

NS_ASSUME_NONNULL_END
