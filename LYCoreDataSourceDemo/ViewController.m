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
@property (nonatomic, strong) NSFetchedResultsController *contactResultsController;

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
    NSSortDescriptor *sortDescroptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    self.contactResultsController = [self.dataSource addDelegate:self
                                                          entity:[ContactEntity entityName]
                                                       predicate:nil
                                                 sortDescriptors:@[sortDescroptor]
                                              sectionNameKeyPath:nil];
}

- (void)touchAdd {
    ContactData *contact = [ContactData new];
    NSString *string = @([NSDate date].timeIntervalSince1970).stringValue;
    contact.uid = string;
    contact.name = string;
    contact.phone = string;
    [[ContactDataSource sharedInstance] addObjects:@[contact]];
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
    return [self.dataSource numberOfSections:self.contactResultsController];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfItems:self.contactResultsController
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
                                                    controller:self.contactResultsController];
    cell.textLabel.text = contact.name;
    cell.detailTextLabel.text = contact.phone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactData *contact = [self.dataSource contactAtIndexPath:indexPath controller:self.contactResultsController];
    [[ContactDataSource sharedInstance] deleteObject:contact];
}

#pragma mark - LYDataSourceDelegate

- (void)willChangeContent:(NSFetchedResultsController *)controller {
    if(controller == self.contactResultsController) {
        [self.tableView beginUpdates];
    }
}

- (void)didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
                 atIndex:(NSUInteger)sectionIndex
           forChangeType:(NSFetchedResultsChangeType)type
              controller:(NSFetchedResultsController *)controller {
    if(controller == self.contactResultsController) {
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
             controller:(NSFetchedResultsController *)controller {
    if(controller == self.contactResultsController) {
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

- (void)didChangeContent:(NSFetchedResultsController *)controller {
    if(controller == self.contactResultsController) {
        [self.tableView endUpdates];
    }
}

@end
