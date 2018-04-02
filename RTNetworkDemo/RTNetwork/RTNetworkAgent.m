//
//  RTNetworkAgent.m
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "RTNetworkAgent.h"
#import "RTNetworkConfig.h"
#import "RTNetworkPrivate.h"
#import <pthread/pthread.h>

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)


@implementation RTNetworkAgent{
    AFHTTPSessionManager *_manager;
    RTNetworkConfig *_config;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlParserResponseSerialzier;
    NSMutableDictionary<NSNumber *, RTBaseRequest *>*_requestsRecord;
    
    dispatch_queue_t _processingQueue;
    pthread_mutex_t _lock;
    NSIndexSet *_allStatusCodes;
}


+ (RTNetworkAgent *)sharedAgent{
    static RTNetworkAgent *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

//初始化_manager、_lock、_requestsRecord、_processingQueue
- (instancetype)init{
    if (self = [super init]) {
        _config = [RTNetworkConfig sharedConfig];
        _manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_config.sesseionConfiguration];
        _requestsRecord = [NSMutableDictionary dictionary];
        _processingQueue = dispatch_queue_create("com.retouch.networkagent.processing", DISPATCH_QUEUE_CONCURRENT);
        _allStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        pthread_mutex_init(&_lock, NULL);
        
        _manager.securityPolicy = _config.securityPolicy;
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager.responseSerializer.acceptableStatusCodes = _allStatusCodes;
        _manager.completionQueue = _processingQueue;
    }
    return self;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer{
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
        _jsonResponseSerializer.acceptableStatusCodes = _allStatusCodes;
    }
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlParserResponseSerialzier{
    if (!_xmlParserResponseSerialzier) {
        _xmlParserResponseSerialzier = [AFXMLParserResponseSerializer serializer];
        _xmlParserResponseSerialzier.acceptableStatusCodes = _allStatusCodes;
    }
    return _xmlParserResponseSerialzier;
}




#pragma mark   -------
- (NSString *)buildRequestUrl:(RTBaseRequest *)request{
    //简单提供参数作为条件就行。该宏评估这个参数，如果为 false ，它就打印一个错误日志信息，该信息包含了参数并且抛出一个异常。
    NSParameterAssert(request != nil);
    
    NSString *detailUrl = [request requestUrl];
    NSURL *temp = [NSURL URLWithString:detailUrl];
    if (temp && temp.host && temp.scheme) {
        return detailUrl;
    }
    
    NSArray *filters = [_config urlFilters];
    for (id<RTUrlFilterProtocol> f in filters) {
        detailUrl = [f filterUrl:detailUrl withRequest:request];
    }
    
    NSString *baseUrl;
    if ([request baseUrl].length > 0) {
        baseUrl = [request baseUrl];
    }else{
        baseUrl = [_config baseUrl];
    }
    
    NSURL *url = [NSURL URLWithString:baseUrl];
    if (baseUrl.length > 0 && ![baseUrl hasPrefix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    return [NSURL URLWithString:detailUrl relativeToURL:url].absoluteString;
}

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(RTBaseRequest *)request{
    AFHTTPRequestSerializer *requestSerializer = nil;
    if (request.requestSerializerType == RTRequestSerializerTypeHTTP) {
        requestSerializer = [AFHTTPRequestSerializer serializer];
    }else if (request.requestSerializerType == RTRequestSerializerTypeJSON){
        requestSerializer = [AFJSONRequestSerializer serializer];
    }
    
    requestSerializer.timeoutInterval = [request requestTimeoutInterval];
    requestSerializer.allowsCellularAccess = [request allowsCellularAccess];
    
    
    return requestSerializer;
}

- (NSURLSessionTask *)sessionTaskForRequest:(RTBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    RTRequestMethod method = [request requestMethod];
    NSString *url = [self buildRequestUrl:request];
    id param = request.requestArgument;
    AFConstructingBlock constructingBlock = [request constructingBodyBlock];
    AFHTTPRequestSerializer *requestSerializer = [self requestSerializerForRequest:request];
    
    switch (method) {
        case RTRequestMethodGET:
            return [self dataTaskWithHTTPMethod:@"GET" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case RTRequestMethodPOST:
            return [self dataTaskWithHTTPMethod:@"POST" requestSerializer:requestSerializer URLString:url parameters:param constructingBodyWithBlock:constructingBlock error:error];
        case RTRequestMethodHEAD:
            return [self dataTaskWithHTTPMethod:@"HEAD" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case RTRequestMethodPUT:
            return [self dataTaskWithHTTPMethod:@"PUT" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case RTRequestMethodDELETE:
            return [self dataTaskWithHTTPMethod:@"DELETE" requestSerializer:requestSerializer URLString:url parameters:param error:error];
        case RTRequestMethodPATCH:
            return [self dataTaskWithHTTPMethod:@"PATCH" requestSerializer:requestSerializer URLString:url parameters:param error:error];
    }
}


/*
 1.确定了request的requestTask属性
 2.将request加入_requestsRecord字典中
 **/
- (void)addRequest:(RTBaseRequest *)request {
    NSParameterAssert(request != nil);
    NSError * __autoreleasing requestSerializationError = nil;
    
    request.requestTask = [self sessionTaskForRequest:request error:&requestSerializationError];
    
    if (requestSerializationError) {
        [self requestDidFailWithRequest:request error:requestSerializationError];
        return;
    }
    
    NSAssert(request.requestTask != nil, @"requestTask should not be nil");
    
    if ([request.requestTask respondsToSelector:@selector(priority)]) {
        switch (request.requestPriority) {
            case RTRequestPriorityHigh:
                if (@available(iOS 8.0, *)) {
                    request.requestTask.priority = NSURLSessionTaskPriorityHigh;
                }
                break;
            case RTRequestPriorityLow:
                if (@available(iOS 8.0, *)) {
                    request.requestTask.priority = NSURLSessionTaskPriorityLow;
                }
                break;
            case RTRequestPriorityDefault:
                /*!!fall through*/
            default:
                if (@available(iOS 8.0, *)) {
                    request.requestTask.priority = NSURLSessionTaskPriorityDefault;
                }
                break;
        }
    }
    
    YTKLog(@"Add request: %@", NSStringFromClass([request class]));
    [self addRequestToRecord:request];    
    [request.requestTask resume];
}

- (void)cancelRequest:(RTBaseRequest *)request {
    NSParameterAssert(request != nil);
    
    [request.requestTask cancel];
    
    [self removeRequestFromRecord:request];
    [request clearCompletionBlock];
}

- (void)cancelAllRequests {
    Lock();
    NSArray *allKeys = [_requestsRecord allKeys];
    Unlock();
    if (allKeys && allKeys.count > 0) {
        NSArray *copiedKeys = [allKeys copy];
        for (NSNumber *key in copiedKeys) {
            Lock();
            RTBaseRequest *request = _requestsRecord[key];
            Unlock();
            // We are using non-recursive lock.
            // Do not lock `stop`, otherwise deadlock may occur.
            [request stop];
        }
    }
}





- (void)handleRequestResult:(NSURLSessionTask *)task responseObject:(id)responseObject error:(NSError *)error {
    Lock();
    RTBaseRequest *request = _requestsRecord[@(task.taskIdentifier)];
    Unlock();
    
    if (!request) {
        return;
    }
    
    YTKLog(@"Finished Request: %@", NSStringFromClass([request class]));
    
    NSError * __autoreleasing serializationError = nil;
    NSError * __autoreleasing validationError = nil;
    
    NSError *requestError = nil;
    BOOL succeed = NO;
    
    request.responseObject = responseObject;
    if ([request.responseObject isKindOfClass:[NSData class]]) {
        request.responseData = responseObject;
        request.responseString = [[NSString alloc] initWithData:responseObject encoding:[RTNetworkUtils stringEncodingWithRequest:request]];
        
        switch (request.responseSerializerType) {
            case RTResponseSerializerTypeHTTP:
                // Default serializer. Do nothing.
                break;
            case RTResponseSerializerTypeJSON:
                request.responseObject = [self.jsonResponseSerializer responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                request.responseJSONObject = request.responseObject;
                break;
            case RTResponseSerializerTypeXMLParser:
                request.responseObject = [self.xmlParserResponseSerialzier responseObjectForResponse:task.response data:request.responseData error:&serializationError];
                break;
        }
    }
    if (error) {
        succeed = NO;
        requestError = error;
    } else if (serializationError) {
        succeed = NO;
        requestError = serializationError;
    } else {
        succeed = [self validateResult:request error:&validationError];
        requestError = validationError;
    }
    
    if (succeed) {
        [self requestDidSucceedWithRequest:request];
    } else {
        [self requestDidFailWithRequest:request error:requestError];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeRequestFromRecord:request];
        [request clearCompletionBlock];
    });
}

- (void)requestDidSucceedWithRequest:(RTBaseRequest *)request {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (request.delegate != nil) {
            [request.delegate requestFinished:request];
        }
        if (request.successCompletionBlock) {
            request.successCompletionBlock(request);
        }
    });
}

- (void)requestDidFailWithRequest:(RTBaseRequest *)request error:(NSError *)error {
    request.error = error;
    YTKLog(@"Request %@ failed, status code = %ld, error = %@",
           NSStringFromClass([request class]), (long)request.responseStatusCode, error.localizedDescription);
    
    // Load response from file and clean up if download task failed.
    if ([request.responseObject isKindOfClass:[NSURL class]]) {
        NSURL *url = request.responseObject;
        if (url.isFileURL && [[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            request.responseData = [NSData dataWithContentsOfURL:url];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:[RTNetworkUtils stringEncodingWithRequest:request]];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        }
        request.responseObject = nil;
    }
    

    dispatch_async(dispatch_get_main_queue(), ^{        
        if (request.delegate != nil) {
            [request.delegate requestFailed:request];
        }
        if (request.failureCompletionBlock) {
            request.failureCompletionBlock(request);
        }
    });
}

- (void)addRequestToRecord:(RTBaseRequest *)request {
    Lock();
    _requestsRecord[@(request.requestTask.taskIdentifier)] = request;
    Unlock();
}

- (void)removeRequestFromRecord:(RTBaseRequest *)request {
    Lock();
    [_requestsRecord removeObjectForKey:@(request.requestTask.taskIdentifier)];
    YTKLog(@"Request queue size = %zd", [_requestsRecord count]);
    Unlock();
}



#pragma mark -
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                           error:(NSError * _Nullable __autoreleasing *)error {
    return [self dataTaskWithHTTPMethod:method requestSerializer:requestSerializer URLString:URLString parameters:parameters constructingBodyWithBlock:nil error:error];
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                               requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                       constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                           error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *request = nil;
    
    if (block) {
        request = [requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:parameters constructingBodyWithBlock:block error:error];
    } else {
        request = [requestSerializer requestWithMethod:method URLString:URLString parameters:parameters error:error];
    }
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request
                           completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *_error) {
                               [self handleRequestResult:dataTask responseObject:responseObject error:_error];
                           }];
    
    return dataTask;
}

- (BOOL)validateResult:(RTBaseRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    BOOL result = [request statusCodeValidator];
    if (!result) {
        if (error) {
            *error = [NSError errorWithDomain:RTRequestValidationErrorDomain code:RTRequestValidationErrorInvalidStatusCode userInfo:@{NSLocalizedDescriptionKey:@"Invalid status code"}];
        }
        return result;
    }
    id json = [request responseJSONObject];
    id validator = [request jsonValidator];
    if (json && validator) {
        result = [RTNetworkUtils validateJSON:json withValidator:validator];
        if (!result) {
            if (error) {
                *error = [NSError errorWithDomain:RTRequestValidationErrorDomain code:RTRequestValidationErrorInvalidJSONFormat userInfo:@{NSLocalizedDescriptionKey:@"Invalid JSON format"}];
            }
            return result;
        }
    }
    return YES;
}


@end
