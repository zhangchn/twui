//
//  BBSNavigationController.h
//  iSMac
//
//  Created by Zhang on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TUIKit.h"

@class ZMNavigationBar;


@interface ZMNavigationController : TUIViewController 

@property(retain) TUIView *contentView;
@property(retain) ZMNavigationBar *navBar;
@property(retain) NSMutableArray *controllers;
@property(readonly) TUIViewController * rootViewController;
@property(readonly) TUIViewController * topViewController;

- (id)initWithRootViewController:(TUIViewController *)rootViewController;
- (TUIViewController *)topViewController;
- (TUIViewController *)rootViewController;
- (void)pushViewController:(TUIViewController *)viewController;
- (void)popViewController;
- (void)popToIndex:(NSUInteger )index;
- (void)popToRootViewController;

@end


@class ZMNavigationBarLayerDelegate;
@interface ZMNavigationBar : TUIControl

@property (assign) __weak ZMNavigationController *navigationController;
@property (retain) ZMNavigationBarLayerDelegate *layerDelegate;
@property (retain) NSMutableArray *items;
@property (assign) NSInteger selectedIndex;

- (id)initWithFrame:(CGRect)frame rootItemName:(NSString *)rootItemName;
- (void)pushTitle:(NSString *)aTitle;
- (void)popTitle;
- (void)popToIndex:(NSUInteger )index;
- (void)replaceTitleAtIndex:(NSUInteger)index withTitle:(NSString *)newTitle;

@end

@interface ZMNavigationBarLayerDelegate : NSObject
@end
