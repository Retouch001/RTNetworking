//
//  ViewController.m
//  RTNetworkDemo
//
//  Created by Tang Retouch on 2018/3/16.
//  Copyright © 2018年 Tang Retouch. All rights reserved.
//

#import "ViewController.h"
#import "TestApi.h"
#import "TestUrlAgumentsFilter.h"
#import "TestAccessory.h"

@interface ViewController ()<RTRequestDelegate>
@property (nonatomic, strong) TestApi *testApi;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    RTNetworkConfig *config = [RTNetworkConfig sharedConfig];
    config.baseUrl = @"http://192.168.8.109:8081";
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    TestUrlAgumentsFilter *urlFilter = [TestUrlAgumentsFilter filterWithArguments:@{@"version": appVersion}];
    [config addUrlFilter:urlFilter];
}

- (TestApi *)testApi{
    if (!_testApi) {
        _testApi = [[TestApi alloc] initWithUsername:@"Retouch" password:@"123456"];
        _testApi.delegate = self;        
    }
    return _testApi;
}

- (IBAction)sendRequest:(id)sender {
    [self.testApi start];
}




#pragma mark   --------------RTRequestDalegate---------------------
- (void)requestFinished:(RTBaseRequest *)request {
    NSLog(@"succeed-------%@",request.responseJSONObject);
    
}
- (void)requestFailed:(RTBaseRequest *)request {
    NSLog(@"failed--------%@",request);
}

@end
