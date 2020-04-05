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
@property (nonatomic, strong) NSMutableDictionary    *mulDictionary;

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
        _mapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                          valueOptions:NSPointerFunctionsWeakMemory];
    }
    
    return _mapTable;
}

- (NSMutableDictionary *)mulDictionary {
    if(!_mulDictionary) {
        _mulDictionary = [NSMutableDictionary dictionary];
    }
    
    return _mulDictionary;
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
            entity:(NSString *)entityName
     syncPredicate:(NSPredicate *)predicate {
    [self addObjects:objects
              entity:entityName
       syncPredicate:predicate
            callback:nil];
}

- (void)addObjects:(NSArray *)objects
            entity:(NSString *)entityName
     syncPredicate:(NSPredicate *)predicate
          callback:(Callback)callback {
    [self.privateContext performBlock:^{
        NSArray *objectsT = objects.copy;
        
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

- (NSArray *)executeFetchOnEntity:(Class)entity
                        predicate:(NSPredicate *)predicate {
    if (![NSThread currentThread].isMainThread) {
        NSAssert(NO, @"Please invoke this method in main thread !");
    }
    
    NSFetchRequest *fetchRequest = [entity performSelector:@selector(fetchRequest)];
    fetchRequest.predicate = predicate;
    
    NSArray *results = nil;
    NSError *error = nil;
    results = [self.mainContext executeFetchRequest:fetchRequest
                                              error:&error];
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

- (void)registerDelegate:(id<LYDataSourceDelegate>)delegate
                 dataKey:(NSString *)dataKey
                  entity:(NSString *)entityName
               predicate:(NSPredicate *)predicate
         sortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors
      sectionNameKeyPath:(NSString *)sectionNameKeyPath {
    if(![NSThread isMainThread]) {
        NSAssert(NO, @"should be initialized on the main thread!");
    }
    
    NSFetchedResultsController *controller = [self.mulDictionary objectForKey:dataKey];
    if(!controller) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
        [fetchRequest setSortDescriptors:sortDescriptors];
        controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                         managedObjectContext:self.mainContext
                                                           sectionNameKeyPath:sectionNameKeyPath
                                                                    cacheName:nil];
        controller.delegate = self;
    }
    
    [controller.fetchRequest setPredicate:predicate];
    [controller.fetchRequest setSortDescriptors:sortDescriptors];
    
    [self.mapTable setObject:delegate forKey:dataKey];
    [self.mulDictionary setObject:controller forKey:dataKey];
    
    NSError *error = nil;
    if (![controller performFetch:&error]) {
        NSLog(@"Failed to initialize FetchedResultsController: %@\n%@", [error localizedDescription], [error userInfo]);
        abort();
    }
}

- (NSInteger)numberOfSections:(NSString *)dataKey {
    return [[[self.mulDictionary objectForKey:dataKey] sections] count];
}

- (NSInteger)numberOfItems:(NSString *)dataKey
                 inSection:(NSInteger)section {
    NSArray *sections = [[self.mulDictionary objectForKey:dataKey] sections];
    if (0 == [sections count]) {
        return 0;
    }
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    
    NSInteger num = [sectionInfo numberOfObjects];
    
    return num;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath dataKey:(NSString *)dataKey {
    return [[self.mulDictionary objectForKey:dataKey] objectAtIndexPath:indexPath];
}

- (id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section
                                                 dataKey:(NSString *)dataKey {
    NSArray *sections = [[self.mulDictionary objectForKey:dataKey] sections];
    if ([sections count] == 0) {
        return nil;
    }
    
    return [sections objectAtIndex:section];
}

- (NSArray *)allObjects:(NSString *)dataKey {
    return [[self.mulDictionary objectForKey:dataKey] fetchedObjects];
}

- (NSArray *)sectionIndexTitles:(NSString *)dataKey {
    return [[self.mulDictionary objectForKey:dataKey] sectionIndexTitles];
}

- (NSString *)dataKeyForController:(NSFetchedResultsController *)controller {
    for (NSString *key in [self.mulDictionary keyEnumerator]) {
        if ([self.mulDictionary objectForKey:key] == controller) {
            return key;
        }
    }
    
    return nil;
}

- (id <LYDataSourceDelegate>)delegateForDataKey:(NSString *)dataKey {
    id delegate;
    if (dataKey) {
        delegate = [self.mapTable objectForKey:dataKey];
        if (!delegate) {
            [self.mulDictionary removeObjectForKey:dataKey];
            return nil;
        }
    }
    
    return delegate;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    NSString *dataKey = [self dataKeyForController:controller];
    id<LYDataSourceDelegate> delegate = [self delegateForDataKey:dataKey];
    
    if(delegate && [delegate respondsToSelector:@selector(didChangeSection:atIndex:forChangeType:dataKey:)]) {
        [delegate didChangeSection:sectionInfo
                           atIndex:sectionIndex
                     forChangeType:type
                           dataKey:dataKey];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    NSString *dataKey = [self dataKeyForController:controller];
    id<LYDataSourceDelegate> delegate = [self delegateForDataKey:dataKey];
    
    if(delegate && [delegate respondsToSelector:@selector(didChangeObject:atIndexPath:forChangeType:newIndexPath:dataKey:)]) {
        [delegate didChangeObject:anObject
                      atIndexPath:indexPath
                    forChangeType:type
                     newIndexPath:newIndexPath
                          dataKey:dataKey];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSString *dataKey = [self dataKeyForController:controller];
    id<LYDataSourceDelegate> delegate = [self delegateForDataKey:dataKey];
    
    if(delegate && [delegate respondsToSelector:@selector(didChangeContent:)]) {
        [delegate didChangeContent:dataKey];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSString *dataKey = [self dataKeyForController:controller];
    id<LYDataSourceDelegate> delegate = [self delegateForDataKey:dataKey];
    
    if(delegate && [delegate respondsToSelector:@selector(willChangeContent:)]) {
        [delegate willChangeContent:dataKey];
    }
}

@end
