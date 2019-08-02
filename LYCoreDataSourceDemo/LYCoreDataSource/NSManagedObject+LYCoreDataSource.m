//
//  NSManagedObject+LYCoreDataSource.m
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "NSManagedObject+LYCoreDataSource.h"

@implementation NSManagedObject (LYCoreDataSource)

+ (NSString *)entityName {
    return NSStringFromClass([self class]);
}

@end
