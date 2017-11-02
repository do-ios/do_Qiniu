//
//  do_Qiniu_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Qiniu_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import <CommonCrypto/CommonHMAC.h>
#import <QiniuSDK/QiniuSDK.h>
#import <QiniuSDK/QNUrlSafeBase64.h>
#import "doIOHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <QiniuSDK/QiniuManager.h>

@implementation do_Qiniu_SM
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
//异步
- (void)download:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    NSString *_callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    //_invokeResult设置返回值
    NSString *domainName = [doJsonHelper GetOneText:_dictParas :@"domainName" :@""];
    NSString *fileName = [doJsonHelper GetOneText:_dictParas :@"fileName" :@""];
    NSString *path = [doJsonHelper GetOneText:_dictParas :@"path" :@""];
    NSString *accessKey = [doJsonHelper GetOneText:_dictParas :@"accessKey" :@""];
    NSString *secretKey = [doJsonHelper GetOneText:_dictParas :@"secretKey" :@""];
    NSString *url = [domainName stringByAppendingPathComponent:fileName];
    url = [NSString stringWithFormat:@"http://%@",url];
    NSString *sdFilePath = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentApp :path];
    QiniuManager *manager = [QiniuManager shargeManager];
    @try {
        if (![self isBlankString:accessKey] && ![self isBlankString:secretKey]) {
            long long deadline = [self getDeadline];
            url = [NSString stringWithFormat:@"%@?e=%llu",url,deadline];
            NSString *hash = [self hmac_sha1:secretKey text:url];
            hash = [QNUrlSafeBase64 encodeString:hash];
            NSString *token = [self getToken:hash withAccessKey:accessKey];
            url = [NSString stringWithFormat:@"%@&token=%@",url,token];
        }
        else
        {
//            url = [QNUrlSafeBase64 encodeString:url];
        }
            __block int64_t size = 0;
            [manager head:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] parameters:nil success:^(NSURLSessionDataTask *task) {
                size = task.countOfBytesReceived;
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                
            }];
            NSMutableDictionary *node = [NSMutableDictionary dictionary];
            [manager down:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] progress:^(NSProgress *downloadProgress) {
                [node setObject:@(size) forKey:@"fileSize"];
                [node setObject:[NSString stringWithFormat:@"%.2f",downloadProgress.fractionCompleted] forKey:@"percent"];
                doInvokeResult *invoke = [[doInvokeResult alloc]init:self.UniqueKey];
                [invoke SetResultNode:node];
                [self.EventCenter FireEvent:@"progress" :invoke];
            } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                return [NSURL fileURLWithPath:sdFilePath];
            } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                BOOL success = YES;
                if (error) {
                    success = NO;
                }
                [_invokeResult SetResultBoolean:success];
                [_scritEngine Callback:_callbackName :_invokeResult];
            }];
    } @catch (NSException *exception) {
        
    }
}
- (void)upload:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    
    NSString *_callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    //_invokeResult设置返回值
    NSString *filePath = [doJsonHelper GetOneText:_dictParas :@"filePath" :@""];
    NSString *accessKey = [doJsonHelper GetOneText:_dictParas :@"accessKey" :@""];
    NSString *secretKey = [doJsonHelper GetOneText:_dictParas :@"secretKey" :@""];
    NSString *bucket = [doJsonHelper GetOneText:_dictParas :@"bucket" :@""];
    NSString *saveName = [doJsonHelper GetOneText:_dictParas :@"saveName" :@""];
    if ([self isBlankString:saveName]) {
        saveName = [filePath lastPathComponent];
    }
    //拼接请求token
    NSString *scope = [NSString stringWithFormat:@"%@:%@",bucket,saveName];
    long long deadline = [self getDeadline];
    deadline = 1489032000;
    NSString *putPolicy = [NSString stringWithFormat:@"{\"scope\":\"%@\",\"deadline\":%llu}",scope,deadline];
    NSString *encodedPutPolicy = [QNUrlSafeBase64 encodeString:putPolicy];
    NSString *sign = [self hmac_sha1:secretKey text:encodedPutPolicy];
    NSString *encodedSign = [QNUrlSafeBase64 encodeString:sign];
    NSString *uploadToken = [NSString stringWithFormat:@"%@:%@:%@",accessKey,sign,encodedPutPolicy];
    NSString *sdFilePath = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentApp :filePath];
    if (![doIOHelper ExistFile:sdFilePath]) {
        NSException *err = [[NSException alloc]initWithName:@"do_Qiniu" reason:@"filePath不存在" userInfo:nil];
        [[doServiceContainer Instance].LogEngine WriteError:err :@""];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:err];
    }
    NSFileManager *fm;
    fm = [NSFileManager defaultManager];
    NSDictionary *fileDict = [fm attributesOfItemAtPath:sdFilePath error:nil];
    NSNumber *fileSize = [fileDict objectForKey:NSFileSize];
    NSMutableDictionary *node = [NSMutableDictionary dictionary];
    QiniuManager *manager = [QiniuManager shargeManager];
    [manager upload:sdFilePath key:saveName token:uploadToken progress:^(NSString *key, float percent) {
        [node setObject:fileSize forKey:@"fileSize"];
        [node setObject:[NSString stringWithFormat:@"%.2f",percent*100] forKey:@"percent"];
        doInvokeResult *invoke = [[doInvokeResult alloc]init:self.UniqueKey];
        [invoke SetResultNode:node];
        [self.EventCenter FireEvent:@"progress" :invoke];
    } success:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        BOOL success;
        if (info.ok) {
            success = YES;
        }
        else
        {
            success = NO;
        }
        [_invokeResult SetResultBoolean:success];
        [_scritEngine Callback:_callbackName :_invokeResult];
    }];
    
}
#pragma mark - 私有方法
- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}
- (long long)getDeadline
{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    long long dTime = [[NSNumber numberWithDouble:timeInterval] longLongValue];
    return (dTime + 3600);
}
- (NSString *)hmac_sha1:(NSString *)key text:(NSString *)text{
    
    const char *cKey  = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [text cStringUsingEncoding:NSUTF8StringEncoding];
    
    char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA1_DIGEST_LENGTH];
    NSString *hash = [HMAC base64Encoding];//base64Encoding函数在NSData+Base64中定义（NSData+Base64网上有很多资源）
    
    return hash;
}

- (NSString *)getToken:(NSString *)hash withAccessKey:(NSString *)accessKey
{
    NSString *token = [NSString stringWithFormat:@"%@:%@",accessKey,hash];
    return token;
}
@end










