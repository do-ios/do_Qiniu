//
//  QiniuManager.h
//  QiniuSDK
//
//  Created by yz on 17/3/1.
//  Copyright © 2017年 DeviceOne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QiniuSDK.h"

@interface QiniuManager : NSObject
+ (QiniuManager*) shargeManager;
- (void)get:(NSString *)url parameters:(NSDictionary *)parameters progress:(  void(^)(NSProgress *downloadProgress))progress success:( void(^)(NSURLSessionDataTask * task, id  responseObject))success failure:( void(^)(NSURLSessionDataTask * _Nullable task,NSError *error))failure;
- (void)upload:(NSString *)filePath key:(NSString *)key token:(NSString *)token progress:(QNUpProgressHandler)progressHandler success:(QNUpCompletionHandler)successHandler;


- (void)down:(NSString *)url progress:(void(^)(NSProgress *downloadProgress))downloadProgressBlock destination:(NSURL *(^)(NSURL *targetPath,NSURLResponse *response))destination completionHandler:(void (^)(NSURLResponse *response,NSURL *filePath,NSError *error))completionHandler;
- (void)head:(NSString *)url parameters:(id)parameters success:(void (^)(NSURLSessionDataTask *task))success failure:(void(^)(NSURLSessionDataTask *task,NSError *error))failure;
@end














