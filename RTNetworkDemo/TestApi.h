//
//  TestApi.h
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/19.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "RTBaseRequest.h"

@interface TestApi : RTBaseRequest

- (id)initWithUsername:(NSString *)username password:(NSString *)password;

@end

