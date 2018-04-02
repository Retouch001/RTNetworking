//
//  RTBaseRequest.m
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "RTBaseRequest.h"
#import "RTNetworkAgent.h"
#import "RTNetworkPrivate.h"

#if __has_include(<AFNetworkin/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

NSString *const RTRequestValidationErrorDomain = @"com.retouch.request.validation";

@interface RTBaseRequest ()

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSData *responseData;
@property (nonatomic, strong, readwrite) id responseJSONObject;
@property (nonatomic, strong, readwrite) id responseObject;
@property (nonatomic, strong, readwrite) NSString *responseString;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation RTBaseRequest


#pragma mark - Request and Response Information
- (NSHTTPURLResponse *)response {
    return (NSHTTPURLResponse *)self.requestTask.response;
}

- (NSInteger)responseStatusCode {
    return self.response.statusCode;
}

- (NSDictionary *)responseHeaders {
    return self.response.allHeaderFields;
}

- (NSURLRequest *)currentRequest {
    return self.requestTask.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.requestTask.originalRequest;
}

- (BOOL)isCancelled {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateCanceling;
}

- (BOOL)isExecuting {
    if (!self.requestTask) {
        return NO;
    }
    return self.requestTask.state == NSURLSessionTaskStateRunning;
}




#pragma mark - Request Configuration
- (void)setCompletionBlockWithSuccess:(RTRequestCompletionBlock)success
                              failure:(RTRequestCompletionBlock)failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // 解决循环引用的问题
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)addAccessory:(id<RTRequestAccessory>)accessory {
    if (!self.requestAccessories) {
        self.requestAccessories = [NSMutableArray array];
    }
    [self.requestAccessories addObject:accessory];
}


#pragma mark - Request Action
- (void)start {
    [self toggleAccessoriesWillStartCallBack];
    [[RTNetworkAgent sharedAgent] addRequest:self];
}

- (void)stop {
    [self toggleAccessoriesWillStopCallBack];
    self.delegate = nil;
    [[RTNetworkAgent sharedAgent] cancelRequest:self];
    [self toggleAccessoriesDidStopCallBack];
}

- (void)startWithCompletionBlockWithSuccess:(RTRequestCompletionBlock)success
                                    failure:(RTRequestCompletionBlock)failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}



#pragma mark - Subclass Override
- (NSString *)requestUrl {
    return @"";
}

- (NSString *)baseUrl {
    return @"";
}

- (NSTimeInterval)requestTimeoutInterval {
    return 60;
}

- (id)requestArgument {
    return nil;
}

- (RTRequestMethod)requestMethod {
    return RTRequestMethodPOST;
}

- (RTRequestSerializerType)requestSerializerType {
    return RTRequestSerializerTypeHTTP;
}

- (RTResponseSerializerType)responseSerializerType {
    return RTResponseSerializerTypeJSON;
}

- (NSArray *)requestAuthorizationHeaderFieldArray {
    return nil;
}

- (NSDictionary *)requestHeaderFieldValueDictionary {
    return nil;
}

- (BOOL)allowsCellularAccess {
    return YES;
}

- (id)jsonValidator {
    return nil;
}

- (BOOL)statusCodeValidator {
    NSInteger statusCode = [self responseStatusCode];
    return (statusCode >= 200 && statusCode <= 299);
}

#pragma mark - NSObject
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ } { arguments: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod, self.requestArgument];
}


@end
