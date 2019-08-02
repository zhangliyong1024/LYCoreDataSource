//
//  ContactDataSource.h
//  CoreDataTest
//
//  Created by zhangliyong on 27/07/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "LYCoreDataSource.h"
#import "ContactEntity+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface ContactData : NSObject

@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *phone;

@end

@interface ContactDataSource : LYDataSource

@end

NS_ASSUME_NONNULL_END
