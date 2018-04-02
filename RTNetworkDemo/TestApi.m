//
//  TestApi.m
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/19.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "TestApi.h"


@implementation TestApi{
    NSString *_username;
    NSString *_password;
}


//初始化的时候将两个参数值传入
- (id)initWithUsername:(NSString *)username password:(NSString *)password {
    self = [super init];
    if (self) {
        _username = username;
        _password = password;
    }
    return self;
}


- (NSString *)requestUrl {
    return @"/appServer/sleepReport/test";
}


- (id)requestArgument {
    return @{
             @"username": _username,
             @"password": _password
             };
}


- (id)jsonValidator{
    return @{@"password" : [NSString class],
             @"username" : [NSString class],
             @"version" : [NSString class]
             };
}




//- (void)toggleAccessoriesWillStartCallBack{
//    NSLog(@"请求将要开始");
//}


- (void)toggleAccessoriesWillStopCallBack{
    NSLog(@"请求将要停止");
}

- (void)toggleAccessoriesDidStopCallBack{
    NSLog(@"请求已经停止");
}


@end
