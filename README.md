# LYCoreDataSource

### 简介

基于三层MOC设计的CoreData数据持久化助手

![image](https://kxl-001.oss-cn-beijing.aliyuncs.com/kxl-help/3moc.jpg)

### 安装

- CocoaPods

```
pod 'LYCoreDataSource'
```

- 手动

可将源码中的LYCoreDataSource文件夹直接拖入你的项目，导入LYCoreDataSource.h头文件即可使用！

### 使用教程

> 下面的教程默认用户没有在创建项目的时候勾选Use CoreData选项，如果勾选了，请删除Appdelete.m和.h中的CoreData初始化代码。

1. 创建模型文件

如果还没有创建模型文件，现在需要你新建一个模型文件。

2. 创建抽象实体基类

源码中的模型文件中我已经创建好了一个BaseEntity，注意看右侧扩展栏中已经勾选上了Abstract Entity。表面这个实体类不会被实例化，只能被子类继承。实体类创建完成后给实体类添加一个syncFlag属性，后面我们在做数据同步时会用到。

3. 导入头文件
```
#import "LYCoreDataSource.h"
```

4. 初始化CoreDataStack

```
[[LYDataSourceManager manager] initCoreDataStackWithMOM:@"LYCoreDataSourceDemo"
                                                     sqlite:@"LYCoreDataSourceDemo"
                                                   callback:^{
                                                       // 处理和和持久化相关的操作
                                                   }];
```

5. CRUD

参考Demo中的用法。

### 联系方式

zhangliyong1997@gmail.com
