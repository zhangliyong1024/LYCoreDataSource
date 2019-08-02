//
//  LYDataSourceManager.m
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "LYDataSourceManager.h"

@interface LYDataSourceManager()

@property (nonatomic, strong) NSManagedObjectContext       *rootContext;
@property (nonatomic, strong) NSManagedObjectContext       *mainContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, copy)   NSString                     *MOMName;
@property (nonatomic, copy)   NSString                     *sqliteName;

@end

@implementation LYDataSourceManager

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    static LYDataSourceManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [LYDataSourceManager new];
    });
    
    return manager;
}

- (void)initCoreDataStackWithMOM:(NSString *)MOMName
                          sqlite:(NSString *)sqliteName
                        callback:(Callback)callback {
    self.MOMName = MOMName;
    self.sqliteName = sqliteName;
    
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    // 作为Core Data初始化的一部分，将持久性存储（NSPersistentStore）添加到持久性存储协调器（NSPersistentStoreCoordinator）会是一个比较耗时的过程，
    // 该操作可能需要一段未知的时间，并且在主队列上执行该操作可能会阻塞用户界面，由于iOS对应用的启动时间有限制，这样的阻塞可能会导致应用程序的终止，
    // 这里我们添加到后台队列，在添加完成后回调主队类继续其他操作。
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                           configuration:nil
                                                                     URL:[self storeUrl]
                                                                 options:nil
                                                                   error:&error]) {
            if (error != nil) {
                NSLog(@"Failed to initalize persistent store: %@\n%@", [error localizedDescription], [error userInfo]);
                abort();
            }
        }
        
        if (!callback) {
            return;
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            callback();
        });
    });
}

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)setSqliteName:(NSString *)sqliteName {
    _sqliteName = [sqliteName stringByReplacingOccurrencesOfString:@".sqlite" withString:@""];
}

- (NSURL *)storeUrl {
    NSString *sqliteName = [NSString stringWithFormat:@"%@.sqlite", self.sqliteName];
    NSURL *url = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:sqliteName];
    NSLog(@"Data base location: %@", url.path);
    
    return url;
}

- (NSManagedObjectModel *)managedObjectModel {
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.MOMName
                                              withExtension:@"momd"];
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

// 根上下文负责与持久化存储器交互
- (NSManagedObjectContext *)rootContext {
    if(!_rootContext) {
        _rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _rootContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    
    return _rootContext;
}

// 主上下文负责UI相关，尽量不要在主线程做CRUD，有专门的私有上下文来执行上述可能耗时的操作
- (NSManagedObjectContext *)mainContext {
    if(!_mainContext) {
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = self.rootContext;
    }
    
    return _mainContext;
}

// 私有上下文负责以同步或者异步的方式执行CRUD
- (NSManagedObjectContext *)newPrivateContext {
    NSManagedObjectContext *pc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    pc.parentContext = self.mainContext;
    
    return pc;
}

// 递归逐级向父类执行save
- (void)save:(NSManagedObjectContext *)context {
    if(!context) {
        return;
    }
    
    NSError *error = nil;
    if([context hasChanges] && ![context save:&error]) {
        NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
    }
    
    if(context.parentContext) {
        [self save:context.parentContext];
    }
}

/*
 如果项目有需求用到ObjectID，需要开启下面的通知到每个上下文进行同步
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(contextViewSave:)
 name:NSManagedObjectContextWillSaveNotification
 object:_rootContext];
 
 - (void)contextViewSave:(NSNotification *)notification {
 NSManagedObjectContext *context = notification.object;
 NSSet *insertedObjects = [context insertedObjects];
 
 if([insertedObjects count]) {
 NSError *error = nil;
 if(![context obtainPermanentIDsForObjects:insertedObjects.allObjects error:&error]) {
 NSLog(@"Failed to obtainPermanentIDsForObjects: %@\n%@", [error localizedDescription], [error userInfo]);
 }
 }
 }
 */

@end
