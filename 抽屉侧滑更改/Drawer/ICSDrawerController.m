//
//  ICSDrawerController.m
//
//  Created by Vito Modena
//
//  Copyright (c) 2014 ice cream studios s.r.l. - http://icecreamstudios.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "ICSDrawerController.h"
#import "ICSDropShadowView.h"

static const CGFloat kICSDrawerControllerDrawerDepth = 260.0f;  //抽屉的深度
static const CGFloat kICSDrawerControllerLeftViewInitialOffset = -60.0f;    //左边抽屉初始偏移量
static const NSTimeInterval kICSDrawerControllerAnimationDuration = 0.5;   //动画时长
static const CGFloat kICSDrawerControllerOpeningAnimationSpringDamping = 0.7f;  //打开抽屉的弹簧效果阻尼
static const CGFloat kICSDrawerControllerOpeningAnimationSpringInitialVelocity = 0.1f;  //打开抽屉的弹簧效果初速度
static const CGFloat kICSDrawerControllerClosingAnimationSpringDamping = 1.0f;  //关闭抽屉的弹簧效果阻尼
static const CGFloat kICSDrawerControllerClosingAnimationSpringInitialVelocity = 0.5f;  //关闭抽屉的弹簧效果阻尼

typedef NS_ENUM(NSUInteger, ICSDrawerControllerState)
{
    ICSDrawerControllerStateClosed = 0,
    ICSDrawerControllerStateOpening,
    ICSDrawerControllerStateOpen,
    ICSDrawerControllerStateClosing
};



@interface ICSDrawerController () <UIGestureRecognizerDelegate>

@property(nonatomic, strong, readwrite) UIViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting> *leftViewController;  //抽屉视图
@property(nonatomic, strong, readwrite) UIViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting> *centerViewController;//中心视图

@property(nonatomic, strong) UIView *leftView;
@property(nonatomic, strong) ICSDropShadowView *centerView;

@property(nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;  //点击手势
@property(nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;  //拖动手势
@property(nonatomic, assign) CGPoint panGestureStartLocation;   //拖动的起点位置

@property(nonatomic, assign) ICSDrawerControllerState drawerState;

@property(nonatomic, assign) BOOL isOpenDrawer;

@end



@implementation ICSDrawerController


+ (instancetype)drawerWithMenuViewController:(UIViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting> *)menuViewController centerViewController:(UIViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting> *)centerViewController
{
    return [[[self class] alloc] initWithLeftViewController:menuViewController centerViewController:centerViewController];
}


- (id)initWithLeftViewController:(UIViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting> *)leftViewController
            centerViewController:(UIViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting> *)centerViewController
{
    NSParameterAssert(leftViewController);
    NSParameterAssert(centerViewController);
    
    self = [super init];
    if (self) {
        _leftViewController = leftViewController;
        _centerViewController = centerViewController;
        
        if ([_leftViewController respondsToSelector:@selector(setDrawer:)]) {
            _leftViewController.drawer = self;
        }
        if ([_centerViewController respondsToSelector:@selector(setDrawer:)]) {
            _centerViewController.drawer = self;
        }
    }
    
    return self;
}

- (void)addCenterViewController
{
    NSParameterAssert(self.centerViewController);
    NSParameterAssert(self.centerView);
    
    //添加子控制器
    [self addChildViewController:self.centerViewController];
    self.centerViewController.view.frame = self.view.bounds;
    [self.centerView addSubview:self.centerViewController.view];
    [self.centerViewController didMoveToParentViewController:self];
}

#pragma mark - Managing the view

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // Initialize left and center view containers
    self.leftView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.centerView = [[ICSDropShadowView alloc] initWithFrame:self.view.bounds];    
    self.leftView.autoresizingMask = self.view.autoresizingMask;
    self.centerView.autoresizingMask = self.view.autoresizingMask;
    
    // Add the center view container
    [self.view addSubview:self.centerView];

    // Add the center view controller to the container
    //添加子控制器到Container
    [self addCenterViewController];
    //设置手势
    [self setupGestureRecognizers];
}

- (BOOL)isOpen
{
    return self.isOpenDrawer;
}

#pragma mark - Configuring the view’s layout behavior

- (UIViewController *)childViewControllerForStatusBarHidden
{
    NSParameterAssert(self.leftViewController);
    NSParameterAssert(self.centerViewController);
    
    if (self.drawerState == ICSDrawerControllerStateOpening) {
        return self.leftViewController;
    }
    return self.centerViewController;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    NSParameterAssert(self.leftViewController);
    NSParameterAssert(self.centerViewController);
    
    if (self.drawerState == ICSDrawerControllerStateOpening) {
        return self.leftViewController;
    }
    return self.centerViewController;
}

#pragma mark - Gesture recognizers

- (void)setupGestureRecognizers
{
    NSParameterAssert(self.centerView);
    //点击手势
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
    //拖动手势
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    self.panGestureRecognizer.maximumNumberOfTouches = 1;
    self.panGestureRecognizer.delegate = self;
    
    [self.centerView addGestureRecognizer:self.panGestureRecognizer];
}

- (void)addClosingGestureRecognizers
{
    NSParameterAssert(self.centerView);
    NSParameterAssert(self.panGestureRecognizer);
    
    [self.centerView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)removeClosingGestureRecognizers
{
    NSParameterAssert(self.centerView);
    NSParameterAssert(self.panGestureRecognizer);

    [self.centerView removeGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark Tap to close the drawer
- (void)tapGestureRecognized:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [self close];   //点击cenrerView关闭抽屉
    }
}

#pragma mark Pan to open/close the drawer
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    NSParameterAssert([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]);
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self.view];
    
    //是否能滑动__update_Lili_2016.05.21
    BOOL canSlide = self.openDirction == DrawerOpenDirctionRight? velocity.x > 0.0f : velocity.x < 0.0f;
    
    if (self.drawerState == ICSDrawerControllerStateClosed && canSlide /*velocity.x > 0.0f*/)
    {
        return YES;
    }
    else if (self.drawerState == ICSDrawerControllerStateOpen && !canSlide /*velocity.x < 0.0f*/)
    {
        return YES;
    }
    
    return NO;
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)panGestureRecognizer
{
    NSParameterAssert(self.leftView);
    NSParameterAssert(self.centerView);
    
    UIGestureRecognizerState state = panGestureRecognizer.state;        //滑动状态
    CGPoint location = [panGestureRecognizer locationInView:self.view]; //滑动位置
    CGPoint velocity = [panGestureRecognizer velocityInView:self.view]; //滑动速度
//    CGSize size = [UIScreen mainScreen].bounds.size;    //屏幕尺寸
    
    switch (state)
    {
            //开始滑动
        case UIGestureRecognizerStateBegan:
            self.panGestureStartLocation = location;
            if (self.drawerState == ICSDrawerControllerStateClosed)
            {
                [self willOpen];
            }
            else
            {
                [self willClose];
            }
            break;
            //滑动中
        case UIGestureRecognizerStateChanged:
        {
            CGFloat delta = 0.0f;
            if (self.drawerState == ICSDrawerControllerStateOpening) {
                delta = location.x - self.panGestureStartLocation.x;
            }
            else if (self.drawerState == ICSDrawerControllerStateClosing) {
                if(self.openDirction == DrawerOpenDirctionRight)
                {
                    delta = kICSDrawerControllerDrawerDepth - (self.panGestureStartLocation.x - location.x);
                }
                else
                {
                    delta = (location.x - self.panGestureStartLocation.x) - kICSDrawerControllerDrawerDepth;
                }
            }
            
            CGRect l = self.leftView.frame;
            CGRect c = self.centerView.frame;
            if (/*delta*/fabs(delta) > kICSDrawerControllerDrawerDepth) {
                l.origin.x = 0.0f;
                c.origin.x = self.openDirction == DrawerOpenDirctionRight? kICSDrawerControllerDrawerDepth : -kICSDrawerControllerDrawerDepth;
            }
            else if (self.openDirction == DrawerOpenDirctionRight? delta < 0.0f : delta >= 0.0f) {
                l.origin.x = self.openDirction == DrawerOpenDirctionRight? kICSDrawerControllerLeftViewInitialOffset : -kICSDrawerControllerLeftViewInitialOffset;
                c.origin.x = 0.0f;
            }
            else
            {
                // While the centerView can move up to kICSDrawerControllerDrawerDepth points, to achieve a parallax effect
                // the leftView has move no more than kICSDrawerControllerLeftViewInitialOffset points
                if(self.openDirction == DrawerOpenDirctionRight)
                {
                    l.origin.x = kICSDrawerControllerLeftViewInitialOffset
                    - (delta * kICSDrawerControllerLeftViewInitialOffset) / kICSDrawerControllerDrawerDepth;
                }
                else
                {
                    l.origin.x = (delta * kICSDrawerControllerLeftViewInitialOffset) / kICSDrawerControllerDrawerDepth;
                }

                c.origin.x = delta;
            }
            
            self.leftView.frame = l;
            self.centerView.frame = c;
            
            break;
        }
            //滑动结束
        case UIGestureRecognizerStateEnded:

            if (self.drawerState == ICSDrawerControllerStateOpening) {
                CGFloat centerViewLocation = self.centerView.frame.origin.x;
                if (/*centerViewLocation*/ fabs(centerViewLocation) == kICSDrawerControllerDrawerDepth) {
                    // Open the drawer without animation, as it has already being dragged in its final position
                    [self setNeedsStatusBarAppearanceUpdate];
                    [self didOpen];
                }
                else if (/*centerViewLocation*/fabs(centerViewLocation) > self.view.bounds.size.width / 3
                         && /*velocity.x*/fabs(velocity.x) > 0.0f) {
                    // Animate the drawer opening
                    [self animateOpening];
                }
                else {
                    // Animate the drawer closing, as the opening gesture hasn't been completed or it has
                    // been reverted by the user
                    [self didOpen];
                    [self willClose];
                    [self animateClosing];
                }

            } else if (self.drawerState == ICSDrawerControllerStateClosing) {
                CGFloat centerViewLocation = self.centerView.frame.origin.x;
                if (centerViewLocation == 0.0f) {
                    // Close the drawer without animation, as it has already being dragged in its final position
                    [self setNeedsStatusBarAppearanceUpdate];
                    [self didClose];
                }
                else if (/*centerViewLocation*/fabs(centerViewLocation) < (2 * self.view.bounds.size.width) / 3
                         && self.openDirction == DrawerOpenDirctionRight? velocity.x < 0.0f : velocity.x > 0.0f) {
                    // Animate the drawer closing
                    [self animateClosing];
                }
                else {
                    // Animate the drawer opening, as the opening gesture hasn't been completed or it has
                    // been reverted by the user
                    [self didClose];

                    // Here we save the current position for the leftView since
                    // we want the opening animation to start from the current position
                    // and not the one that is set in 'willOpen'
                    CGRect l = self.leftView.frame;
                    [self willOpen];
                    self.leftView.frame = l;
                    
                    [self animateOpening];
                }
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - Animations
#pragma mark Opening animation
- (void)animateOpening
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateOpening);
    NSParameterAssert(self.leftView);
    NSParameterAssert(self.centerView);
    
    // Calculate the final frames for the container views
    CGRect leftViewFinalFrame = self.view.bounds;
    CGRect centerViewFinalFrame = self.view.bounds;
    //根据传入的方向来判断打开的方向
    centerViewFinalFrame.origin.x = self.openDirction == DrawerOpenDirctionRight? kICSDrawerControllerDrawerDepth : -kICSDrawerControllerDrawerDepth;
    
    [UIView animateWithDuration:kICSDrawerControllerAnimationDuration
                          delay:0
         usingSpringWithDamping:kICSDrawerControllerOpeningAnimationSpringDamping
          initialSpringVelocity:kICSDrawerControllerOpeningAnimationSpringInitialVelocity
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.centerView.frame = centerViewFinalFrame;
                         self.leftView.frame = leftViewFinalFrame;
                         
                         [self setNeedsStatusBarAppearanceUpdate];
                     }
                     completion:^(BOOL finished) {
                         [self didOpen];
                     }];
}

#pragma mark Closing animation
- (void)animateClosing
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateClosing);
    NSParameterAssert(self.leftView);
    NSParameterAssert(self.centerView);
    
    // Calculate final frames for the container views
    CGRect leftViewFinalFrame = self.leftView.frame;
    //根据传入的方向判断关闭的位置
    leftViewFinalFrame.origin.x = self.openDirction == DrawerOpenDirctionRight? kICSDrawerControllerLeftViewInitialOffset : -kICSDrawerControllerLeftViewInitialOffset;
    CGRect centerViewFinalFrame = self.view.bounds;
    
    [UIView animateWithDuration:kICSDrawerControllerAnimationDuration
                          delay:0
         usingSpringWithDamping:kICSDrawerControllerClosingAnimationSpringDamping
          initialSpringVelocity:kICSDrawerControllerClosingAnimationSpringInitialVelocity
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.centerView.frame = centerViewFinalFrame;
                         self.leftView.frame = leftViewFinalFrame;
                         
                         [self setNeedsStatusBarAppearanceUpdate];
                     }
                     completion:^(BOOL finished) {
                         [self didClose];
                     }];
}

#pragma mark - 打开或关闭

/**
 *  打开或关闭抽屉
 */
- (void)performDrawer
{
    if(self.isOpen)
    {
        [self close];
    }
    else
    {
        [self open];
    }
}

#pragma mark - Opening the drawer

- (void)open
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateClosed);

    [self willOpen];
    
    [self animateOpening];
}

- (void)willOpen
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateClosed);
    NSParameterAssert(self.leftView);
    NSParameterAssert(self.centerView);
    NSParameterAssert(self.leftViewController);
    NSParameterAssert(self.centerViewController);
    
    // Keep track that the drawer is opening
    self.drawerState = ICSDrawerControllerStateOpening;
    
    // Position the left view
    CGRect f = self.view.bounds;
    //根据传入的方向来判断leftView的位置
    if(self.openDirction == DrawerOpenDirctionRight)
    {
        f.origin.x = kICSDrawerControllerLeftViewInitialOffset;
        NSParameterAssert(f.origin.x < 0.0f);
    }
    else
    {
        f.origin.x = -kICSDrawerControllerLeftViewInitialOffset;
        NSParameterAssert(f.origin.x > 0.0f);
    }
    
    self.leftView.frame = f;    //设置leftView的frame 位置纵坐标 -60
    
    // Start adding the left view controller to the container
    //添加子控制器 leftViewController 到 Container
    [self addChildViewController:self.leftViewController];
    self.leftViewController.view.frame = self.leftView.bounds;
    [self.leftView addSubview:self.leftViewController.view];

    // Add the left view to the view hierarchy
    //将leftView添加到centerView下面
    [self.view insertSubview:self.leftView belowSubview:self.centerView];
    
    // Notify the child view controllers that the drawer is about to open
    //通知子视图控制器即将打开
    if ([self.leftViewController respondsToSelector:@selector(drawerControllerWillOpen:)]) {
        [self.leftViewController drawerControllerWillOpen:self];
    }
    if ([self.centerViewController respondsToSelector:@selector(drawerControllerWillOpen:)]) {
        [self.centerViewController drawerControllerWillOpen:self];
    }
}

- (void)didOpen
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateOpening);
    NSParameterAssert(self.leftViewController);
    NSParameterAssert(self.centerViewController);
    
    // Complete adding the left controller to the container
    [self.leftViewController didMoveToParentViewController:self];
    
    [self addClosingGestureRecognizers];
    
    // Keep track that the drawer is open
    self.drawerState = ICSDrawerControllerStateOpen;
    
    // Notify the child view controllers that the drawer is open
    if ([self.leftViewController respondsToSelector:@selector(drawerControllerDidOpen:)]) {
        [self.leftViewController drawerControllerDidOpen:self];
    }
    if ([self.centerViewController respondsToSelector:@selector(drawerControllerDidOpen:)]) {
        [self.centerViewController drawerControllerDidOpen:self];
    }
    
    self.isOpenDrawer = YES;
}

#pragma mark - Closing the drawer

- (void)close
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateOpen);

    [self willClose];

    [self animateClosing];
}

- (void)willClose
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateOpen);
    NSParameterAssert(self.leftViewController);
    NSParameterAssert(self.centerViewController);
    
    // Start removing the left controller from the container
    [self.leftViewController willMoveToParentViewController:nil];
    
    // Keep track that the drawer is closing
    self.drawerState = ICSDrawerControllerStateClosing;
    
    // Notify the child view controllers that the drawer is about to close
    if ([self.leftViewController respondsToSelector:@selector(drawerControllerWillClose:)]) {
        [self.leftViewController drawerControllerWillClose:self];
    }
    if ([self.centerViewController respondsToSelector:@selector(drawerControllerWillClose:)]) {
        [self.centerViewController drawerControllerWillClose:self];
    }
}

- (void)didClose
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateClosing);
    NSParameterAssert(self.leftView);
    NSParameterAssert(self.centerView);
    NSParameterAssert(self.leftViewController);
    NSParameterAssert(self.centerViewController);
    
    // Complete removing the left view controller from the container
    [self.leftViewController.view removeFromSuperview];
    [self.leftViewController removeFromParentViewController];
    
    // Remove the left view from the view hierarchy
    [self.leftView removeFromSuperview];
    
    [self removeClosingGestureRecognizers];
    
    // Keep track that the drawer is closed
    self.drawerState = ICSDrawerControllerStateClosed;
    
    // Notify the child view controllers that the drawer is closed
    if ([self.leftViewController respondsToSelector:@selector(drawerControllerDidClose:)]) {
        [self.leftViewController drawerControllerDidClose:self];
    }
    if ([self.centerViewController respondsToSelector:@selector(drawerControllerDidClose:)]) {
        [self.centerViewController drawerControllerDidClose:self];
    }
    
    self.isOpenDrawer = NO;
}

#pragma mark - Reloading/Replacing the center view controller

- (void)reloadCenterViewControllerUsingBlock:(void (^)(void))reloadBlock
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateOpen);
    NSParameterAssert(self.centerViewController);
    
    [self willClose];
    
    CGRect f = self.centerView.frame;
    f.origin.x = self.view.bounds.size.width;
    
    [UIView animateWithDuration: kICSDrawerControllerAnimationDuration / 2
                     animations:^{
                         self.centerView.frame = f;
                     }
                     completion:^(BOOL finished) {
                         // The center view controller is now out of sight
                         if (reloadBlock) {
                             reloadBlock();
                         }
                         // Finally, close the drawer
                         [self animateClosing];
                     }];
}

- (void)replaceCenterViewControllerWithViewController:(UIViewController<ICSDrawerControllerChild, ICSDrawerControllerPresenting> *)viewController
{
    NSParameterAssert(self.drawerState == ICSDrawerControllerStateOpen);
    NSParameterAssert(viewController);
    NSParameterAssert(self.centerView);
    NSParameterAssert(self.centerViewController);
    
    [self willClose];
    
    CGRect f = self.centerView.frame;
    f.origin.x = self.view.bounds.size.width;
    
    [self.centerViewController willMoveToParentViewController:nil];
    [UIView animateWithDuration: kICSDrawerControllerAnimationDuration / 2
                     animations:^{
                         self.centerView.frame = f;
                     }
                     completion:^(BOOL finished) {
                         // The center view controller is now out of sight
                         
                         // Remove the current center view controller from the container
                         if ([self.centerViewController respondsToSelector:@selector(setDrawer:)]) {
                             self.centerViewController.drawer = nil;
                         }
                         [self.centerViewController.view removeFromSuperview];
                         [self.centerViewController removeFromParentViewController];
                         
                         // Set the new center view controller
                         self.centerViewController = viewController;
                         if ([self.centerViewController respondsToSelector:@selector(setDrawer:)]) {
                             self.centerViewController.drawer = self;
                         }
                         
                         // Add the new center view controller to the container
                         [self addCenterViewController];
                         
                         // Finally, close the drawer
                         [self animateClosing];
                     }];
}

@end
