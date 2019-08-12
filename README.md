# LYCoreDataSource

### 架构介绍

基于三层MOC设计的CoreData数据持久化框架！

![image](https://kxl-001.oss-cn-beijing.aliyuncs.com/kxl-help/3moc.jpg)

### 安装

- CocoaPods

```
pod 'LYCoreDataSource'
```

- 手动

可将源码中的LYCoreDataSource文件夹直接拖入你的项目，导入LYCoreDataSource.h头文件即可使用！

### 使用教程

> 下面的教程默认用户没有在创建项目的时候勾选Use CoreData选项，如果勾选了，请删除Appdelete.m和.h中的对应的CoreData默认初始化代码。

1. 创建模型文件

如果还没有创建模型文件，现在需要你新建一个模型文件。

2. 创建抽象实体基类

源码中的模型文件中我已经创建好了一个BaseEntity，注意看右侧扩展栏中已经勾选上了Abstract Entity。表明这个实体类不会被实例化，只能被子类继承。实体类创建完成后给实体类添加一个syncFlag属性，后面我们在做数据同步时会用到。

3. 导入头文件
```
#import "LYCoreDataSource.h"
```

4. 初始化CoreDataStack

推荐您根据不同环境初始化对应的模型和数据库，您需要填入三个参数，MOM（模型文件名称）、sqliteName（数据库文件名称）、databaseKey（用来做强制更新），具体参考源码有对应的解释。

```
// 在app启动后立即初始化CoreDataStack
- (void)initCoreData {
    NSString *MOM, *sqlite, *databaseKey;
#ifdef ENV_DEV
    MOM = @"Model";
    sqlite = @"dev.sqlite";
    databaseKey = @"1000";
#else
    MOM = @"Model";
    sqlite = @"pub.sqlite";
    databaseKey = @"1000";
#endif
    [[LYCoreDataManager manager] initCoreDataStackWithMOM:MOM
                                                   sqlite:sqlite
                                              databaseKey:databaseKey];
}
```
5. 创建实体

在模型文件中通过可视化操作添加你需要的实体，唯一要注意的是如果你的实体的实例化对象需要同步的需求，那么需要继承之前创建的BaseEntity。

6. 创建数据源

接下来你需要继承LYDataSource创建自己的数据源，这里推荐按照功能去分别创建不同的数据源。例如：IM应用中联系人是一个数据源，群组是另外一个数据源。
我在LYDataSource基类中封装了一个单独MOC来处理数据增删改查，同时LYDataSource也提供了便捷的UI绑定方法，让你更快速的处理UITableView的数据更新。

7. 重写基类的方法

- sharedInstance 初始化数据源，分配单独的MOC
- entityNameForObject 因为一个数据源可能涉及不同的实体，后面处理添加删除的操作时需要知道数据对应的具体实体
- onAddObject 添加数据方法
- onDeleteObject 删除数据方法

### 原理

本打算详细从头写这个框架的设计及实现，但是估计能用这个框架的也都是对CoreData有一定研究的，所以下面只描述几个关键性的点。

- 添加持久性存储（NSPersistentStore）到持久性存储协调器（NSPersistentStoreCoordinator）

源码中这里没有做后台处理，主要是为了简化操作。如果感觉这个操作阻塞了主线程或者优化启动时间，可以考虑后台添加，添加完成后回调主线程处理其他和数据库相关事宜。但是，这样做代码需要处理的东西较多，所以我这里没这么设计。

- 避免主线程阻塞

框架在设计的时候采用了3层分层，每一层有各自的任务，主线程只负责UI绑定相关，私有上下文负责异步处理增删改查，根上下文负责将数据同步到持久化存储器。私有上下文针对单独的数据源，私有上下文的每次增删都需要将save提交给主上下文，主上下文将结果通知给UI，主上下文再将save操作提交给根上下文。所以save操作在框架中是递归操作的。

- 为什么不将查询操作放在主上下文

理论上是可以的，但是框架这种分层设计，每个数据源都对应一个私有上下文，一种数据源只会在一个私有上下文处理，没有必要单独去主线程查询，况且查询操作有时也比较耗时，可能会阻塞主线程。

- NSManagedObjectContext的线程安全

在CoreData中NSManagedObjectContext本身不是线程安全的，虽然你可以操作多线程处理一个上下文，可能有时没问题，但是出了问题就很严重。所以苹果推荐一个线程只操作一个上下文。但是这个规范需要每个开发者去遵守，代码中无法去做限制。所以源码中针对添加（onAddObject）删除（onDeleteObject）操作给与了提示。

```
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
```
- 数据合并的问题

正常来说，不同的上下文可以处理不同的实体，这样可能会导致数据冲突，这就需要我们配置上下文的合并策略。所以为了避免这种问题，框架在设计时将同一种实体只关联到一个数据源中，因为每个私有上下文只关联一个数据源，而每个私有上下文是关联一个私有队列的，这样针对同一实体的操作只会在一个上下文中出现并且串行异步处理，从而避免了多上下文操作同一实体可能出现的冲突问题。但是，这样做也会导致一个问题，如果针对某一个实体的操作并发较高，这样就会带来性能问题。但是，考虑到前端这种情况比较少见，框架优先考虑易用性，而放弃了性能这块。

- 数据迁移问题

CoreData本身是支持数据迁移的，但是迁移代码比较繁琐。框架本着简单易用的原则，在每次初始化数据库的时候会根据模型文件计算hash值，来判断Model中的实体是否有修改，只要hash值和上一次的比对不一致就会清空数据库，避免CoreData奔溃，同时框架也提供了一个databaseKey字段用来强制清空数据库，有时App某个版本的数据库出现问题或者有脏数据，可以通过修改databaseKey来强制清空。

- relationship问题

框架对于这块没有支持，所以在设计多个实体关系的时候尽量通过id来关联。

### 联系方式

zhangliyong1997@gmail.com
