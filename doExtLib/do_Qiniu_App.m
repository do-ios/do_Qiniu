//
//  do_Qiniu_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Qiniu_App.h"
static do_Qiniu_App* instance;
@implementation do_Qiniu_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Qiniu_App alloc]init];
    return instance;
}
@end
