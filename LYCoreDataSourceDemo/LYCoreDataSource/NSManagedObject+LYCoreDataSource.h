//
//  NSManagedObject+LYCoreDataSource.h
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObject (LYCoreDataSource)

+ (NSString *)entityName;

@end

NS_ASSUME_NONNULL_END
