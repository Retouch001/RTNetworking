//
//  RTNetworkPrivate.h
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTBaseRequest.h"
#import "RTNetworkAgent.h"
#import "RTNetworkConfig.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void YTKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

@class AFHTTPSessionManager;


@interface RTNetworkUtils : NSObject

+ (BOOL)validateJSON:(id)json withValidator:(id)jsonValidator;
+ (void)addDoNotBackupAttribute:(NSString *)path;
+ (NSString *)md5StringFromString:(NSString *)string;
+ (NSString *)appVersionString;
+ (NSStringEncoding)stringEncodingWithRequest:(RTBaseRequest *)request;
+ (BOOL)validateResumeData:(NSData *)data;

@end



@interface RTBaseRequest (RequestAccessory)

- (void)toggleAccessoriesWillStartCallBack;
- (void)toggleAccessoriesWillStopCallBack;
- (void)toggleAccessoriesDidStopCallBack;

@end



@interface RTBaseRequest (Setter)

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite, nullable) NSData *responseData;
@property (nonatomic, strong, readwrite, nullable) id responseJSONObject;
@property (nonatomic, strong, readwrite, nullable) id responseObject;
@property (nonatomic, strong, readwrite, nullable) NSString *responseString;
@property (nonatomic, strong, readwrite, nullable) NSError *error;

@end

NS_ASSUME_NONNULL_END
