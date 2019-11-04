//
//  ViewController.m
//  LYCoreDataSourceDemo
//
//  Created by Polly polly on 02/08/2019.
//  Copyright © 2019 zhangliyong. All rights reserved.
//

#import "ViewController.h"
#import "ContactDataSource.h"

@interface ViewController () < UITableViewDataSource, UITableViewDelegate, LYDataSourceDelegate >

@property (nonatomic, strong) UITableView                *tableView;

@property (nonatomic, strong) ContactDataSource          *dataSource;
@property (nonatomic, copy)   NSString                   *dataKey;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"点击删除";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(touchAdd)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"同步"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(syncAllData)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                  style:UITableViewStylePlain];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.view addSubview:self.tableView];
    
    [self registerDataBase];
}

- (void)registerDataBase {
    self.dataSource = [ContactDataSource sharedInstance];
    self.dataKey = NSStringFromClass([self class]);
    NSSortDescriptor *sortDescroptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [self.dataSource registerDelegate:self
                              dataKey:self.dataKey
                               entity:[ContactEntity entityName]
                            predicate:nil
                      sortDescriptors:@[sortDescroptor]
                   sectionNameKeyPath:nil];
}

- (void)touchAdd {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ContactData *contact = [ContactData new];
        NSString *string = @([NSDate date].timeIntervalSince1970).stringValue;
        contact.uid = string;
        contact.name = string;
        contact.phone = string;
        [[ContactDataSource sharedInstance] addObjects:@[contact]];
    });
}

- (void)syncAllData {
    // 同步操作
    ContactData *contact = [ContactData new];
    contact.uid = @"10086";
    contact.name = @"关羽";
    contact.phone = @"1234567890";
    // predicate不填，默认同步所有数据
    [[ContactDataSource sharedInstance] addObjects:@[contact]
                                     syncPredicate:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView  {
    return [self.dataSource numberOfSections:self.dataKey];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfItems:self.dataKey
                                inSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"contactCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier];
    }
    
    ContactData *contact = [self.dataSource contactAtIndexPath:indexPath
                                                       dataKey:self.dataKey];
    cell.textLabel.text = contact.name;
    cell.detailTextLabel.text = contact.phone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactData *contact = [self.dataSource contactAtIndexPath:indexPath dataKey:self.dataKey];
    [[ContactDataSource sharedInstance] deleteObject:contact];
}

#pragma mark - LYDataSourceDelegate

- (void)willChangeContent:(NSString *)dataKey {
    if([self.dataKey isEqualToString:dataKey]) {
        [self.tableView beginUpdates];
    }
}

- (void)didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
                 atIndex:(NSUInteger)sectionIndex
           forChangeType:(NSFetchedResultsChangeType)type
                 dataKey:(nonnull NSString *)dataKey {
    if([self.dataKey isEqualToString:dataKey]) {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeMove:
            case NSFetchedResultsChangeUpdate:
                break;
        }
    }
}

- (void)didChangeObject:(id)anObject
            atIndexPath:(NSIndexPath *)indexPath
          forChangeType:(NSFetchedResultsChangeType)type
           newIndexPath:(NSIndexPath *)newIndexPath
                dataKey:(nonnull NSString *)dataKey {
    if([self.dataKey isEqualToString:dataKey]) {
        switch(type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)didChangeContent:(NSString *)dataKey {
    if([self.dataKey isEqualToString:dataKey]) {
        [self.tableView endUpdates];
    }
}

@end
