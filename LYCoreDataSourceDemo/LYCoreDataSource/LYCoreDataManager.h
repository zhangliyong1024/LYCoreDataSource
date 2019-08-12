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

@interface LYCoreDataManager : NSObject

+ (instancetype)manager;

- (void)initCoreDataStackWithMOM:(NSString *)MOMName
                          sqlite:(NSString *)sqliteName
                     databaseKey:(NSString *)databaseKey;

- (NSManagedObjectContext *)newPrivateContext;

- (void)save:(NSManagedObjectContext *)context;

@end

NS_ASSUME_NONNULL_END
