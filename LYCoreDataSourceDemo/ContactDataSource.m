//
//  ContactDataSource.m
//  CoreDataTest
//
//  Created by zhangliyong on 27/07/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "ContactDataSource.h"

@implementation ContactData

+ (instancetype)contactFromEntity:(ContactEntity *)item {
    return [[self alloc] initWithEntity:item];
}

- (instancetype)initWithEntity:(ContactEntity *)entity {
    if (self = [super init]) {
        self.uid = entity.uid;
        self.name = entity.name;
        self.phone = entity.phone;
    }
    
    return self;
}

@end

@implementation ContactDataSource

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static ContactDataSource *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[ContactDataSource alloc] initWithPrivateContext:[[LYCoreDataManager manager] newPrivateContext]];
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

- (ContactData *)contactWithUid:(NSString *)uid {
    ContactEntity *entity = [self executeFetchRequest:[ContactEntity fetchRequest]
                                            predicate:[NSPredicate predicateWithFormat:@"uid == %@", uid]].firstObject;
    
    return [ContactData contactFromEntity:entity];
}

- (ContactData *)contactAtIndexPath:(NSIndexPath *)indexPath controller:(NSFetchedResultsController *)controller {
    ContactEntity *entity = [self objectAtIndexPath:indexPath controller:controller];
    
    return [ContactData contactFromEntity:entity];
}

@end
