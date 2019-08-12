//
//  LYDataSource.m
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "LYDataSource.h"

@interface LYDataSource() < NSFetchedResultsControllerDelegate >

@property (nonatomic, strong) NSManagedObjectContext *privateContext;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSMapTable             *mapTable;

@end

@implementation LYDataSource

+ (instancetype)sharedInstance {
    NSAssert(NO, @"implement this method in your sub-class");
    return nil;
}

- (instancetype)initWithPrivateContext:(NSManagedObjectContext *)privateContext {
    if(self = [super init]) {
        self.privateContext = privateContext;
        self.mainContext = privateContext.parentContext;
    }
    
    return self;
}

- (NSMapTable *)mapTable {
    if(!_mapTable) {
        // NSFetchedResultsController作为key需使用强引用，对delegate对象使用弱引用
        _mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                          valueOptions:NSPointerFunctionsWeakMemory];
    }
    
    return _mapTable;
}

- (void)addObject:(id)object {
    [self addObjects:@[object]];
}

- (void)addObjects:(NSArray *)objects {
    [self addObjects:objects
            callback:nil];
}

- (void)addObject:(id)object
         callback:(nullable Callback)callback {
    [self addObjects:@[object]
            callback:callback];
}

- (void)addObjects:(NSArray *)objects
          callback:(nullable Callback)callback {
    [self.privateContext performBlock:^{
        NSArray *objectsT = objects.copy;
        
        for(id object in objectsT) {
            [self onAddObject:object];
        }
        
        [[LYCoreDataManager manager] save:self.privateContext];
        
        if(callback) {
            callback();
        }
    }];
}

- (void)addObjects:(NSArray *)objects
     syncPredicate:(NSPredicate *)predicate {
    [self addObjects:objects
       syncPredicate:predicate
            callback:nil];
}

- (void)addObjects:(NSArray *)objects
     syncPredicate:(NSPredicate *)predicate
          callback:(Callback)callback {
    [self.privateContext performBlock:^{
        NSArray *objectsT = objects.copy;
        NSString *entityName = [self entityNameForObject:objectsT.firstObject];
        
        BOOL syncFlag = NO;
        NSEntityDescription *desc = [NSEntityDescription entityForName:entityName
                                                inManagedObjectContext:self.privateContext];
        for (NSPropertyDescription *item in desc.properties) {
            if ([item.name isEqualToString:@"syncFlag"]) {
                syncFlag = YES;
                break;
            }
        }
        
        NSArray *oldData = nil;
        if (syncFlag) {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
            request.predicate = predicate;
            oldData = [self.privateContext executeFetchRequest:request error:nil];
            for (NSManagedObject *item in oldData) {
                [item setValue:@0 forKey:@"syncFlag"];
            }
        }
        
        for(id object in objectsT) {
            NSManagedObject *item = [self onAddObject:object];
            if(syncFlag) {
                [item setValue:@1 forKey:@"syncFlag"];
            }
        }
        
        if (syncFlag) {
            for (NSManagedObject *item in oldData) {
                NSNumber *value = [item valueForKey:@"syncFlag"];
                if (![item isDeleted] && [value integerValue] == 0) {
                    [self.privateContext deleteObject:item];
                }
            }
        }
        
        [[LYCoreDataManager manager] save:self.privateContext];
        
        if(callback) {
            callback();
        }
    }];
}

- (void)deleteObject:(id)object {
    [self deleteObjects:@[object]];
}

- (void)deleteObjects:(NSArray *)objects {
    [self deleteObjects:objects
               callback:nil];
}

- (void)deleteObject:(id)object
            callback:(nullable Callback)callback {
    [self deleteObjects:@[object]
               callback:callback];
}

- (void)deleteObjects:(NSArray *)objects
             callback:(Callback)callback {
    [self.privateContext performBlock:^{
        NSArray *objectsT = objects.copy;
        
        for (id object in objectsT) {
            [self onDeleteObject:object];
        }
        
        [[LYCoreDataManager manager] save:self.privateContext];
        
        if(callback) {
            callback();
        }
    }];
}

- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchRequest
                       predicate:(NSPredicate *)predicate {
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSArray *results = [self.privateContext executeFetchRequest:fetchRequest error:&error];
    if(error) {
        NSAssert(NO, @"Error executeFetchRequest: %@\n%@", [error localizedDescription], [error userInfo]);
    }
    
    return results;
}
 
- (NSString *)entityNameForObject:(id)object {
    NSAssert(NO, @"implement this method in your sub-class");
    return nil;
}

/*
 * 子类在实现onAddObject时，内部所有操作必须使用本类的privateContext
 * 禁止出现使用其他context的情况以避免context线程安全问题
 */

- (NSManagedObject *)onAddObject:(id)object {
    NSAssert(NO, @"implement this method in your sub-class");
    return nil;
}

/*
 * 子类在实现onDeleteObject时，内部所有操作必须使用本类的privateContext
 * 禁止出现使用其他context的情况以避免context线程安全问题
 */

- (void)onDeleteObject:(id)object {
    NSAssert(NO, @"implement this method in your sub-class");
}

- (NSFetchedResultsController *)addDelegate:(id<LYDataSourceDelegate>)delegate
                                     entity:(NSString *)entityName
                                  predicate:(NSPredicate *)predicate
                            sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
                         sectionNameKeyPath:(NSString *)sectionNameKeyPath {
    // 数据绑定主要还是用在UI相关，所以我们这里限定在主线程操作
    if(![NSThread isMainThread]) {
        NSAssert(NO, @"should be initialized on the main thread!");
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = sortDescriptors;
    
    // 绑定到mainContext
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:self.mainContext
                                                                                                 sectionNameKeyPath:sectionNameKeyPath
                                                                                                          cacheName:nil];
    fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Failed to initialize FetchedResultsController: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
    
    [self.mapTable setObject:delegate forKey:fetchedResultsController];
    
    return fetchedResultsController;
}

- (NSInteger)numberOfSections:(NSFetchedResultsController *)controller {
    return [[controller sections] count];
}

- (NSInteger)numberOfItems:(NSFetchedResultsController *)controller
                 inSection:(NSInteger)section {
    NSArray *sections = [controller sections];
    if (0 == [sections count]) {
        return 0;
    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    NSInteger num = [sectionInfo numberOfObjects];
    
    return num;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath controller:(NSFetchedResultsController *)controller {
    return [controller objectAtIndexPath:indexPath];
}

- (id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section
                                              controller:(NSFetchedResultsController *)controller {
    NSArray *sections = [controller sections];
    if ([sections count] == 0) {
        return nil;
    }
    
    return [sections objectAtIndex:section];
}

- (NSArray *)allObjects:(NSFetchedResultsController *)controller {
    return [controller fetchedObjects];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    id<LYDataSourceDelegate> delegate = [self.mapTable objectForKey:controller];
    if(delegate && [delegate respondsToSelector:@selector(didChangeSection:atIndex:forChangeType:controller:)]) {
        [delegate didChangeSection:sectionInfo
                           atIndex:sectionIndex
                     forChangeType:type
                        controller:controller];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    id<LYDataSourceDelegate> delegate = [self.mapTable objectForKey:controller];
    if(delegate && [delegate respondsToSelector:@selector(didChangeObject:atIndexPath:forChangeType:newIndexPath:controller:)]) {
        [delegate didChangeObject:anObject
                      atIndexPath:indexPath
                    forChangeType:type
                     newIndexPath:newIndexPath
                       controller:controller];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    id<LYDataSourceDelegate> delegate = [self.mapTable objectForKey:controller];
    if(delegate && [delegate respondsToSelector:@selector(didChangeContent:)]) {
        [delegate didChangeContent:controller];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    id<LYDataSourceDelegate> delegate = [self.mapTable objectForKey:controller];
    if(delegate && [delegate respondsToSelector:@selector(willChangeContent:)]) {
        [delegate willChangeContent:controller];
    }
}

@end
