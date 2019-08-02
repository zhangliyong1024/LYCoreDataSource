//
//  ContactDataSource.m
//  CoreDataTest
//
//  Created by zhangliyong on 27/07/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "ContactDataSource.h"

@implementation ContactData

@end

@implementation ContactDataSource

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ContactDataSource *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[ContactDataSource alloc] initWithPrivateContext:[[LYDataSourceManager manager] newPrivateContext]];
    });
    
    return instance;
}

- (NSString *)entityNameForObject:(id)object {
    if([object isKindOfClass:[ContactData class]]) {
        return [ContactEntity entityName];
    }
    
    return nil;
}

- (NSManagedObject *)onAddObject:(id)object {
    if([object isKindOfClass:[ContactData class]]) {
        ContactData *data = (ContactData *)object;
        NSFetchRequest *request = [ContactEntity fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"uid == %@", data.uid];
        
        NSError *error = nil;
        NSArray *results = [self.privateContext executeFetchRequest:request
                                                              error:&error];
        if(error) {
            NSAssert(NO, @"Error executeFetchRequest: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        
        ContactEntity *item = results.firstObject;
        if (!item) {
            item = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ContactEntity class])
                                                 inManagedObjectContext:self.privateContext];
            item.uid = data.uid;
        }
        
        item.name = data.name;
        item.phone = data.phone;
        
        return item;
    }
    
    return nil;
}

- (void)onDeleteObject:(id)object {
    if ([object isKindOfClass:[ContactData class]]) {
        ContactData *data = (ContactData *)object;
        NSFetchRequest *request = [ContactEntity fetchRequest];
        request.predicate = [NSPredicate predicateWithFormat:@"uid == %@", data.uid];
        
        NSError *error = nil;
        NSArray *results = [self.privateContext executeFetchRequest:request
                                                              error:&error];
        if(error) {
            NSAssert(NO, @"Error executeFetchRequest: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        
        ContactEntity *item = results.firstObject;
        if (item && !item.isDeleted) {
            [self.privateContext deleteObject:item];
        }
    }
}

@end
