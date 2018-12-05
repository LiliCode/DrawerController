# DrawerController
基于ICSDrawerController的更改,支持左右滑动. 致谢原作者提供这么好的框架!

如何安装
---
```Ruby
pod 'ICSDrawerController', :git  => 'https://github.com/LiliCode/DrawerController.git'  # 暂不支持版本号
```
怎么使用
---
```objc
//菜单
    MenuTableViewController *menu = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    ViewController *center = (ViewController *)self.window.rootViewController;
    ICSDrawerController *drawer = [ICSDrawerController drawerWithMenuViewController:menu centerViewController:center];
//    drawer.openDirction = DrawerOpenDirctionLeft;   //向左滑动
    drawer.openDirction = DrawerOpenDirctionRight;  //向右滑动
    self.window.rootViewController = drawer;
```
