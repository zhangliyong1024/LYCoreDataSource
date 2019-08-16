//
//  LYDataSourceManager.m
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "LYCoreDataManager.h"
#import "NSData+LYCoreDataSource.h"

@interface LYCoreDataManager()

@property (nonatomic, strong) NSManagedObjectContext       *rootContext;
@property (nonatomic, strong) NSManagedObjectContext       *mainContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, copy)   NSString                     *MOMName;
@property (nonatomic, copy)   NSString                     *sqliteName;

@end

@implementation LYCoreDataManager

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    static LYCoreDataManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [LYCoreDataManager new];
    });
    
    return manager;
}

- (void)initCoreDataStackWithMOM:(NSString *)MOMName
                          sqlite:(NSString *)sqliteName
                     databaseKey:(NSString *)databaseKey {
    self.MOMName = MOMName;
    self.sqliteName = sqliteName;
    
    NSManagedObjectModel *model = [self managedObjectModel];
    NSDictionary *hashs = model.entityVersionHashesByName;
    NSUInteger hash = 0;
    for (NSData *item in hashs.objectEnumerator) {
        NSString *md5 = [item MD5];
        hash += md5.hash;
    }
    
    hash += databaseKey.hash;
    
    NSInteger oldKey = [[NSUserDefaults standardUserDefaults] integerForKey:sqliteName];
    
    if (oldKey != hash) {
        [[NSFileManager defaultManager] removeItemAtURL:[self storeUrl] error:nil];
        [[NSUserDefaults standardUserDefaults] setInteger:hash forKey:sqliteName];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
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
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:self.MOMName withExtension:@"momd"];
    
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

- (NSManagedObjectContext *)mainContext {
    if(!_mainContext) {
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _mainContext.parentContext = self.rootContext;
    }
    
    return _mainContext;
}

- (NSManagedObjectContext *)newPrivateContext {
    NSManagedObjectContext *pc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    pc.parentContext = self.mainContext;
    
    return pc;
}

- (void)save:(NSManagedObjectContext *)context {
    if(!context) {
        return;
    }
    
    if(context == self.mainContext) {
        [self performSelectorOnMainThread:@selector(processSaveForContext:)
                               withObject:context
                            waitUntilDone:NO];
    }
    else {
        [self processSaveForContext:context];
    }
}

- (void)processSaveForContext:(NSManagedObjectContext *)context {
    NSError *error = nil;
    if([context hasChanges] && ![context save:&error]) {
        NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
    }
    
    if(context.parentContext) {
        [self save:context.parentContext];
    }
}

@end
