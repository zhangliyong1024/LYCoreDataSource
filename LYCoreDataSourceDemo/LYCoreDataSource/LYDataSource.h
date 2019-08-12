//
//  LYDataSource.h
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LYCoreDataManager.h"

typedef void (^Callback)(void);

NS_ASSUME_NONNULL_BEGIN

@class LYDataSource;
@class BaseEntity;

@protocol LYDataSourceDelegate <NSObject>

- (void)willChangeContent:(NSFetchedResultsController *)controller;

- (void)didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
                 atIndex:(NSUInteger)sectionIndex
           forChangeType:(NSFetchedResultsChangeType)type
              controller:(NSFetchedResultsController *)controller;

- (void)didChangeObject:(id)anObject
            atIndexPath:(NSIndexPath *)indexPath
          forChangeType:(NSFetchedResultsChangeType)type
           newIndexPath:(NSIndexPath *)newIndexPath
             controller:(NSFetchedResultsController *)controller;

- (void)didChangeContent:(NSFetchedResultsController *)controller;

@end

@interface LYDataSource : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) NSManagedObjectContext *privateContext;

- (instancetype)initWithPrivateContext:(NSManagedObjectContext *)privateContext;

// 异步添加、修改以及删除方法

- (void)addObject:(id)object;

- (void)addObjects:(NSArray *)objects;

- (void)addObject:(id)object
         callback:(nullable Callback)callback;

- (void)addObjects:(NSArray *)objects
          callback:(nullable Callback)callback;

- (void)addObjects:(NSArray *)objects
     syncPredicate:(nullable NSPredicate *)predicate;

- (void)addObjects:(NSArray *)objects
     syncPredicate:(nullable NSPredicate *)predicate
          callback:(nullable Callback)callback;

- (void)deleteObject:(id)object;

- (void)deleteObjects:(NSArray *)objects;

- (void)deleteObject:(id)object
            callback:(nullable Callback)callback;

- (void)deleteObjects:(NSArray *)objects
             callback:(nullable Callback)callback;

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest
                       predicate:(NSPredicate *)predicate;

// 子类可以重写的方法

- (NSString *)entityNameForObject:(id)object;

- (nullable NSManagedObject *)onAddObject:(id)object;

- (void)onDeleteObject:(id)object;

// 数据绑定相关方法

- (NSFetchedResultsController *)addDelegate:(id<LYDataSourceDelegate>)delegate
                                     entity:(NSString *)entityName
                                  predicate:(nullable NSPredicate *)predicate
                            sortDescriptors:(nonnull NSArray<NSSortDescriptor *>*)sortDescriptors
                         sectionNameKeyPath:(nullable NSString *)sectionNameKeyPath;

- (NSInteger)numberOfSections:(NSFetchedResultsController *)controller;

- (NSInteger)numberOfItems:(NSFetchedResultsController *)controller
                 inSection:(NSInteger)section;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
             controller:(NSFetchedResultsController *)controller;

- (id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section
                                              controller:(NSFetchedResultsController *)controller;

- (NSArray *)allObjects:(NSFetchedResultsController *)controller;

@end

NS_ASSUME_NONNULL_END
