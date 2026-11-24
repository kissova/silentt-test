#import <UIKit/UIKit.h>
#include "PUBG/core/MenuLoad/Includes.h"
#import <AVFoundation/AVFoundation.h>
#include "PUBG/core/ue4/xor.h"

#define TOKEN ENCRYPT("wZ3Q/xYPjTIWo5gRdA5jLfamO6POk7SjBPQALRXHafuNi0nwolEDstMEOrlEsxHyiUUj4M/7hRwYD6VApIf9c3kkgQYy6dWE/B69+eT5F0g=")

extern bool menu_open;

@interface ImGuiOverlayWindow : UIWindow
@property (nonatomic, weak) UIView *floatingButtonView;
@end

@implementation ImGuiOverlayWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.floatingButtonView && !self.floatingButtonView.hidden) {
        CGPoint btnPoint = [self convertPoint:point toView:self.floatingButtonView];
        if ([self.floatingButtonView pointInside:btnPoint withEvent:event]) {
            return YES;
        }
    }
    if (!menu_open) {
        return NO;
    }
    return [super pointInside:point withEvent:event];
}
@end

static UIWindowScene *FindActiveWindowScene(void) {
    if (@available(iOS 13.0, *)) {
        UIApplication *app = [UIApplication sharedApplication];
        for (UIScene *scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive &&
                [scene isKindOfClass:[UIWindowScene class]]) {
                return (UIWindowScene *)scene;
            }
        }
        for (UIScene *scene in app.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                return (UIWindowScene *)scene;
            }
        }
    }
    return nil;
}

static UIWindow *FindActiveMainWindow(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindow *win in app.windows) {
        if (![win isKindOfClass:[ImGuiOverlayWindow class]] && win.isKeyWindow) {
            return win;
        }
    }
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *win in windowScene.windows) {
                    if (![win isKindOfClass:[ImGuiOverlayWindow class]] && win.isKeyWindow) {
                        return win;
                    }
                }
                for (UIWindow *win in windowScene.windows) {
                    if (![win isKindOfClass:[ImGuiOverlayWindow class]]) {
                        return win;
                    }
                }
            }
        }
    }
    for (UIWindow *win in app.windows) {
        if (![win isKindOfClass:[ImGuiOverlayWindow class]]) {
            return win;
        }
    }
    return nil;
}

void initAPI(){
    [[ImGuiLoad share] initMenu];
}

@interface ImGuiLoad()
@property (nonatomic, strong) ImGuiOverlayWindow *overlayWindow;
@property (nonatomic, strong) ImGuiDrawView *vna;
@property (nonatomic, strong) UIButton *menuButton;
@property (nonatomic, assign) BOOL gestureInstalled;
- (void)initMenu;
- (void)initFloatingButton:(UIView *)parentView;
- (void)handleButtonTap;
- (void)handleButtonPan:(UIPanGestureRecognizer *)pan;
- (void)initTapGes;
- (void)toggleMenu;
- (void)handleTap:(UITapGestureRecognizer *)gesture;
@end

@implementation ImGuiLoad

+ (void)load { 
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ 
        initAPI();
        [[ImGuiLoad share] initTapGes]; 
    }); 
}

+ (instancetype)share { 
    static ImGuiLoad *tool; 
    static dispatch_once_t onceToken; 
    dispatch_once(&onceToken, ^{ 
        tool = [[ImGuiLoad alloc] init]; 
    }); 
    return tool; 
}

- (void)show { 
    [self initMenu]; 
    if (!_overlayWindow || !_vna.view) return;
    _overlayWindow.hidden = NO;
    _vna.view.hidden = NO; 
    menu_open = true; 
}

- (void)initFloatingButton:(UIView *)parentView {
    if (!parentView) return;
    if (!_menuButton) {
        CGFloat btnSize = 44.0;
        _menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _menuButton.frame = CGRectMake(20.0, 120.0, btnSize, btnSize);
        _menuButton.backgroundColor = [UIColor colorWithWhite:0.06 alpha:0.92];
        _menuButton.layer.cornerRadius = btnSize / 2.0;
        _menuButton.layer.borderWidth = 1.2;
        _menuButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.85].CGColor;
        _menuButton.clipsToBounds = YES;
        [_menuButton setTitle:@"M" forState:UIControlStateNormal];
        [_menuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _menuButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        [_menuButton addTarget:self action:@selector(handleButtonTap) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleButtonPan:)];
        [_menuButton addGestureRecognizer:pan];
    }

    if (_menuButton.superview != parentView) {
        [_menuButton removeFromSuperview];
        [parentView addSubview:_menuButton];
    }
    _overlayWindow.floatingButtonView = _menuButton;
    [parentView bringSubviewToFront:_menuButton];
}

- (void)handleButtonTap {
    [self toggleMenu];
}

- (void)handleButtonPan:(UIPanGestureRecognizer *)pan {
    UIView *superview = _menuButton.superview;
    if (!superview) return;
    CGPoint translation = [pan translationInView:superview];
    CGPoint center = _menuButton.center;
    center.x += translation.x;
    center.y += translation.y;

    CGFloat halfW = _menuButton.bounds.size.width / 2.0 + 8.0;
    CGFloat halfH = _menuButton.bounds.size.height / 2.0 + 8.0;
    center.x = MAX(halfW, MIN(superview.bounds.size.width - halfW, center.x));
    center.y = MAX(halfH, MIN(superview.bounds.size.height - halfH, center.y));

    _menuButton.center = center;
    [pan setTranslation:CGPointZero inView:superview];
}

- (void)initMenu { 
    if (!_overlayWindow) {
        CGRect bounds = [UIScreen mainScreen].bounds;
        UIWindowScene *scene = FindActiveWindowScene();
        if (@available(iOS 13.0, *) && scene) {
            _overlayWindow = [[ImGuiOverlayWindow alloc] initWithWindowScene:scene];
            _overlayWindow.frame = scene.coordinateSpace.bounds;
        } else {
            _overlayWindow = [[ImGuiOverlayWindow alloc] initWithFrame:bounds];
        }
        _overlayWindow.backgroundColor = [UIColor clearColor];
        _overlayWindow.windowLevel = UIWindowLevelAlert + 10;
        _overlayWindow.userInteractionEnabled = YES;

        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        _overlayWindow.rootViewController = rootVC;

        _vna = [[ImGuiDrawView alloc] init]; 
        _vna.view.frame = _overlayWindow.bounds;
        _vna.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _vna.view.userInteractionEnabled = YES; 
        _vna.view.backgroundColor = [UIColor clearColor]; 
        [rootVC.view addSubview:_vna.view]; 
        _vna.view.hidden = YES; 
        _overlayWindow.hidden = NO;
        menu_open = false; 

        [self initFloatingButton:rootVC.view];
    } else {
        UIWindowScene *scene = FindActiveWindowScene();
        if (@available(iOS 13.0, *) && scene && _overlayWindow.windowScene != scene) {
            _overlayWindow.windowScene = scene;
            _overlayWindow.frame = scene.coordinateSpace.bounds;
        }
        _overlayWindow.hidden = NO;
        [self initFloatingButton:_overlayWindow.rootViewController.view];
    }
}

- (void)toggleMenu { 
    [self initMenu];
    if (!_vna.view) return;
    _vna.view.hidden = !_vna.view.hidden; 
    menu_open = !_vna.view.hidden; 
    if (_menuButton && _menuButton.superview) {
        [_menuButton.superview bringSubviewToFront:_menuButton];
    }
}

- (void)initTapGes { 
    if (self.gestureInstalled) return;
    UIWindow *mainWindow = FindActiveMainWindow();
    UIView *targetView = mainWindow.rootViewController.view ?: mainWindow;
    if (!targetView) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self initTapGes];
        });
        return;
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]; 
    tap.numberOfTapsRequired = 2; 
    tap.numberOfTouchesRequired = 2; 
    tap.cancelsTouchesInView = NO;
    [targetView addGestureRecognizer:tap]; 
    self.gestureInstalled = YES;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture { 
    if (gesture.state == UIGestureRecognizerStateEnded) { 
        [self toggleMenu]; 
    } 
}

@end
