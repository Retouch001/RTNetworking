//
//  TestUrlAgumentsFilter.h
//  iSuke
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RTNetworkConfig.h"
#import "RTBaseRequest.h"


@interface TestUrlAgumentsFilter : NSObject<RTUrlFilterProtocol>

+ (TestUrlAgumentsFilter *)filterWithArguments:(NSDictionary *)arguments;

@end
