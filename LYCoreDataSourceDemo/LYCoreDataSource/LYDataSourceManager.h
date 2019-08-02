//
//  LYDataSourceManager.h
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^Callback)(void);

@interface LYDataSourceManager : NSObject

+ (instancetype)manager;

- (void)initCoreDataStackWithMOM:(NSString *)MOMName
                          sqlite:(NSString *)sqliteName
                        callback:(nullable Callback)callback;

- (NSManagedObjectContext *)newPrivateContext;

- (void)save:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
