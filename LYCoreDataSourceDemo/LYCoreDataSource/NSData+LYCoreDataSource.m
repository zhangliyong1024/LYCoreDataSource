//
//  NSData+LYCoreDataSource.m
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 10/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "NSData+LYCoreDataSource.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (LYCoreDataSource)

- (NSString *)MD5 {
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5([self bytes], (CC_LONG)[self length], r);
    NSString *MD5 = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                     r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return [MD5 uppercaseString];
}

- (NSString *)MD5InShort {
    NSString *string = [self MD5];
    return [string substringWithRange:NSMakeRange(8, 16)];
}

@end
