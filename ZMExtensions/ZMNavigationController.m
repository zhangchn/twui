//
//  BBSNavigationController.m
//  iSMac
//
//  Created by Zhang on 7/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ZMNavigationController.h"


@implementation ZMNavigationController
@synthesize controllers, navBar, contentView, rootViewController, topViewController;
- (id)initWithRootViewController:(TUIViewController *)rootVC {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.controllers = [[[NSMutableArray alloc] init] autorelease];
        [self.controllers addObject:rootVC];
        NSString * rootTitle = @" ";
        if ([rootVC respondsToSelector:@selector(title)]) {
            rootTitle = [rootVC performSelector:@selector(title)];
        }
        self.navBar = [[[ZMNavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 30) rootItemName:rootTitle] autorelease];
        self.navBar.navigationController = self;
        if ([rootVC respondsToSelector:@selector(setNavigationController:)]) {
            [rootVC performSelector:@selector(setNavigationController:) withObject:self];
        }
        [rootVC addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:0];
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.controllers = [NSMutableArray array];
    }
    return self;    
}
- (void)loadView{
    //[super viewWillAppear:animated];
    TUIView *baseView = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.contentView = [[[TUIView alloc] initWithFrame:CGRectMake(0, 0, 320, 450)] autorelease];
    self.contentView.autoresizingMask = TUIViewAutoresizingFlexibleWidth|TUIViewAutoresizingFlexibleHeight;
    self.contentView.clipsToBounds=YES;
    [self setView:baseView];
    
    self.navBar.frame = CGRectMake(0, 450, 320, 30);
    self.navBar.autoresizingMask = TUIViewAutoresizingFlexibleWidth | TUIViewAutoresizingFlexibleBottomMargin ;
    [baseView addSubview:self.contentView];
    [baseView addSubview:self.navBar];
//    CGRect bounds = baseView.bounds;
    baseView.backgroundColor = [TUIColor greenColor];
    if ([self.controllers count]) {
        TUIViewController * topVC = [self.controllers objectAtIndex:0];
        //bounds.origin.y-=30;
        topVC.view.autoresizingMask = TUIViewAutoresizingFlexibleWidth|TUIViewAutoresizingFlexibleHeight;
        topVC.view.frame = self.contentView.bounds;
        [self.contentView addSubview:topVC.view];
    }
    //[navBar setNeedsDisplay];
}
- (void)dealloc {
    [super dealloc];
    [self setView:nil];
    [self.navBar removeFromSuperview];
    [self.contentView removeFromSuperview];
    
}

- (TUIViewController *)topViewController{
    return [self.controllers lastObject];
}

- (TUIViewController *)rootViewController {
    if (![self.controllers count]) {
        return nil;
    }
    return [self.controllers objectAtIndex:0];
}

- (void)popViewController {
    if ([self.controllers count]<2) {
        return;
    }
    [self popToIndex:[self.controllers count]-2];
}
- (void)pushViewController:(TUIViewController *)viewController {
    TUIViewController *previousController = [self.controllers lastObject];
    [self.controllers addObject:viewController];
    CGRect bounds = self.contentView.bounds;
    bounds.origin.x += bounds.size.width;
    viewController.view.frame = bounds;
    viewController.view.autoresizingMask = TUIViewAutoresizingFlexibleWidth|TUIViewAutoresizingFlexibleHeight;
    if ([viewController respondsToSelector:@selector(setNavigationController:)]) {
        [viewController performSelector:@selector(setNavigationController:) withObject:self];
    }
    [viewController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:0];
    [self.contentView addSubview:viewController.view];
    [self.navBar pushTitle:[viewController performSelector:@selector(title)]];
    [self.contentView bringSubviewToFront:viewController.view];
    double delayInSeconds = 0.01;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [TUIView animateWithDuration:0.5 animations:^(void) {
            //        CGPoint center = viewController.view.center;
            //        center.x -= bounds.size.width;
            //        viewController.view.center = center;
            CGRect rect = viewController.view.frame;
            rect.origin.x = 00;
            viewController.view.frame = rect;
        } completion:^(BOOL finished) {
            [previousController.view removeFromSuperview];
            if (![[[NSApplication sharedApplication] keyWindow] makeFirstResponder:viewController]){
                NSLog(@"pop set responder fail");
            }
        }];
    });
    
}


- (void)popToIndex:(NSUInteger )index {
    if (index>=[self.controllers count]-1) {
        return;
    }
   
    TUIViewController *vcToRemove = [self.controllers lastObject];
    TUIViewController *vcToShow = [self.controllers objectAtIndex:index];
    [vcToRemove resignFirstResponder];
    [self.contentView insertSubview:vcToShow.view atIndex:0];
    vcToShow.view.frame = self.contentView.bounds;
    vcToShow.view.alpha = 1;
    [TUIView animateWithDuration:0.5 animations:^(void) {
        CGPoint center = vcToRemove.view.center;
        center.x+=self.view.bounds.size.width;
        vcToRemove.view.center = center;
    } completion:^(BOOL finished) {
        [vcToRemove.view removeFromSuperview];
    }];
    [self.navBar popToIndex:index];
    [self.controllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx>index) {
            [obj removeObserver:self forKeyPath:@"title"];
        }
    }];
    [self.controllers removeObjectsInRange:NSMakeRange(index+1, [self.controllers count]-1-index)];
    BOOL res = [[[NSApplication sharedApplication] keyWindow] makeFirstResponder:vcToShow];
    if (!res) {
        NSLog(@"pop set responder fail");
    }
}
- (void)popToRootViewController {
    [self popToIndex:0];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"title"] && [self.controllers containsObject:object] && [change objectForKey:NSKeyValueChangeKindKey]){
        NSUInteger index = [self.controllers indexOfObject:object];
        [self.navBar replaceTitleAtIndex:index withTitle:[object title]];
    }
}
- (BOOL)becomeFirstResponder {
    return YES;
}
- (BOOL)acceptsFirstResponder {
    return YES;
}
@end


@implementation ZMNavigationBar;
@synthesize navigationController, layerDelegate, items, selectedIndex;
- (id)initWithFrame:(CGRect)frame rootItemName:(NSString *)rootItemName{
    self = [super initWithFrame:frame];
    
    if (self) {

        self.items = [[[NSMutableArray alloc] init] autorelease];
        self.layerDelegate = [[[ZMNavigationBarLayerDelegate alloc] init] autorelease];
        self.backgroundColor = [TUIColor grayColor];
        self.layer.backgroundColor = [TUIColor grayColor].CGColor;
        self.layer.layoutManager = [CAConstraintLayoutManager layoutManager];
        
        [self pushTitle:rootItemName];
    }
    return self;
}
- (void)dealloc {
    [super dealloc];
    [self popToIndex:0];
    [[self.items objectAtIndex:0] removeFromSuperlayer];
    self.items = nil;
}

- (void)popToIndex:(NSUInteger)index {
    if (index < [self.items count]-1){
        int i = [self.items count]-1;
        do {
            [self popTitle];
            i--;
        }while (i>index);
    }
    
}
- (void)popNavigationControllerToIndex:(NSUInteger)index {
    if (index < [self.items count]-1){
        int i = [self.items count]-1;
        do {
            [self popTitle];
            i--;
        }while (i>index);
    }
    if ([navigationController respondsToSelector:@selector(popToIndex:)]) {
        [navigationController popToIndex:index];
    }
}

- (void)popTitle {
    if ([self.items count]>1) {
        [[self.items lastObject] removeFromSuperlayer];
        [self.items removeLastObject];
        [[self.items lastObject] setNeedsDisplay];
    }
    return;
}
- (NSString *)shortTitleFromTitle:(NSString *)aTitle {
    NSString *shortTitle = [aTitle stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    if([shortTitle rangeOfString:@"  "].location!=NSNotFound) {
        shortTitle = [[shortTitle 
                           componentsSeparatedByString:@"  "] objectAtIndex:0];
    }
    if([shortTitle rangeOfString:@"　"].location!=NSNotFound) {
        shortTitle = [[shortTitle componentsSeparatedByString:@"　"] objectAtIndex:0];
    }
    return shortTitle;
}

- (void)pushTitle:(NSString *)aTitle {
    CGFloat left = 10;
    NSString *shortTitle = [self shortTitleFromTitle:aTitle];
    CGSize size = [shortTitle sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"Helvetica-Bold",NSFontNameAttribute,@"16",NSFontSizeAttribute, nil]];
    size.width+=4;

    CALayer *aLayer = [CALayer layer];
    aLayer.delegate = self.layerDelegate;
    aLayer.opaque = NO;
    aLayer.backgroundColor = [TUIColor clearColor].CGColor;
    [aLayer setValue:aTitle forKey:@"title"];
    [aLayer setValue:[NSValue valueWithSize:size] forKey:@"textsize"];
    // If this layer is not the first layer
    if ([self.items lastObject]) {
        CGRect aFrame = [[self.items lastObject] frame];
        left = aFrame.origin.x + aFrame.size.width;
    }
    aLayer.frame = CGRectMake(left-10, 0, size.width+20, self.bounds.size.height);

    aLayer.name=[NSString stringWithFormat:@"item%d",[self.items count]];
    [aLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMidY relativeTo:@"superlayer" attribute:kCAConstraintMidY]];
    if(![self.items count]) {
        [aLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:@"superlayer" attribute:kCAConstraintMinX]];
    } else {
        [aLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX relativeTo:[NSString stringWithFormat:@"item%d",[self.items count]] attribute:kCAConstraintMaxX]];
    }

    [self.layer insertSublayer:aLayer atIndex:0];
    [aLayer setNeedsDisplay];
    [self.items addObject:aLayer];

    return;
}

- (void)displayLayer:(CALayer *)layer{
    [super displayLayer:layer];
    if (layer == self.layer) {
        for (CALayer * aLayer in self.items) {
            aLayer.delegate = self.layerDelegate;
            [aLayer setNeedsDisplay];
        }
    }
}

- (void)replaceTitleAtIndex:(NSUInteger)index withTitle:(NSString *)newTitle {
    if (index > [self.items count]-1)
        return;
    CALayer *itemLayer = [self.items objectAtIndex:index];
    [itemLayer setValue:newTitle forKey:@"title"];
    CGSize size = [newTitle sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"Helvetica-Bold",NSFontNameAttribute,@"16",NSFontSizeAttribute, nil]];
    size.width+=4;
    [CATransaction begin];
    [self.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx >=index) {
            
            CGFloat previousMaxX = 10;
            if (idx>0) {
                CGRect previousFrame = [[self.items objectAtIndex:idx-1] frame];
                previousMaxX = previousFrame.origin.x+previousFrame.size.width - 10;
            }
            CGRect newFrame=[obj frame];
            newFrame.origin.x = previousMaxX;
            if (idx==index) {
               newFrame.size.width = size.width + 20;
            }
            [obj setFrame:newFrame];
        }
    }];
    [itemLayer setNeedsDisplay];
    [CATransaction commit];
}

- (void)selectWithIndex:(NSUInteger )index{
    if (index>-1 && index>[self.items count]-1) {
        return;
    }
    CALayer *layer = [self.items objectAtIndex:index];
    [layer setValue:@"1" forKey:@"selected"];
    [layer setNeedsDisplay];
    self.selectedIndex = index;
}
- (void)deselect {
    if (self.selectedIndex > [self.items count]-1) {
        self.selectedIndex = -1;
        return;
    }
    if (self.selectedIndex < 0) {
        return;
    }
    CALayer *layer = [self.items objectAtIndex:self.selectedIndex];
    [layer setValue:@"0" forKey:@"selected"];
    [layer setNeedsDisplay];    
    self.selectedIndex = -1;
}

#pragma mark Control Event Handling
- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    if([event clickCount] < 2) {
		[self sendActionsForControlEvents:TUIControlEventTouchDown];
	} else {
		[self sendActionsForControlEvents:TUIControlEventTouchDownRepeat];
	}
    NSPoint local_point = [self.superview convertPoint:[event locationInWindow] fromView:nil];
    CALayer *layerHit = [self.layer hitTest:local_point];
    if ([self.items containsObject:layerHit]) {
        NSUInteger indexHit = [self.items indexOfObject:layerHit];
        double delayInSeconds = 0.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self selectWithIndex:indexHit];
        });

    }    
}
- (void)mouseUp:(NSEvent *)event
{
    [super mouseUp:event];
    [self performSelector:@selector(deselect) withObject:nil afterDelay:0.02];
    NSPoint local_point = [self.superview convertPoint:[event locationInWindow] fromView:nil];
    CALayer *layerHit = [self.layer hitTest:local_point];
    if([event clickCount] < 2) {
        if([self eventInside:event]) {
            if(![self didDrag]) {
                [self sendActionsForControlEvents:TUIControlEventTouchUpInside];
                if ([self.items containsObject:layerHit]) {
                    [self popNavigationControllerToIndex:[self.items indexOfObject:layerHit]];
                }
            }
        } else {
            [self sendActionsForControlEvents:TUIControlEventTouchUpOutside];
        }
    }
}
@end

@implementation ZMNavigationBarLayerDelegate
- (id)init {
    self = [super init];
    if (self){
        
    }
    return self;
}
- (void)dealloc {
    [super dealloc];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    const CGPoint clip0[] = {
        CGPointMake(0, layer.bounds.size.height),
        CGPointMake(0, 0),
        CGPointMake(layer.bounds.size.width-8, 0) ,
        CGPointMake(layer.bounds.size.width, layer.bounds.size.height/2) ,
        CGPointMake(layer.bounds.size.width-8, layer.bounds.size.height)
    };
    CGContextAddLines(ctx, clip0, 5);
    CGContextClosePath(ctx);
    CGContextClip(ctx);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGFloat components2[]={.8,.8,.8,1,1,1,1,1};
    const CGFloat components3[]={.6,.6,.6,1,.8,.8,.8,1};
    const CGFloat strokeComponents1[]={.9,.9,.9,.8};
    const CGFloat strokeComponents2[]={.2,.2,.2,.2};
    const CGFloat loc[] = {0,1};
    const CGFloat *strokeComponents3;
    CGGradientRef grad;
    if ([[layer valueForKey:@"selected"] isEqual:@"1"]) {
        grad = CGGradientCreateWithColorComponents(colorSpace, components3, loc, 2);
        strokeComponents3 = strokeComponents2;
    } else {
        grad = CGGradientCreateWithColorComponents(colorSpace, components2, loc, 2);
        strokeComponents3 = strokeComponents1;
    }
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(0,0), CGPointMake(0, 30), 0);
    CGGradientRelease(grad);
    CGColorSpaceRelease(colorSpace);
    

    
    const CGFloat strokeComponents0[]={.3,.3,.3,.8};
    
    const CGPoint separator1[] = {CGPointMake(layer.bounds.size.width-8, 0) , CGPointMake(layer.bounds.size.width, layer.bounds.size.height/2) , CGPointMake(layer.bounds.size.width-8, layer.bounds.size.height)};
    const CGPoint separator2[] = {CGPointMake(layer.bounds.size.width-9, 0) , CGPointMake(layer.bounds.size.width-1, layer.bounds.size.height/2) , CGPointMake(layer.bounds.size.width-9, layer.bounds.size.height)};

    CGContextSetStrokeColor(ctx, strokeComponents0);
    CGContextSetLineWidth(ctx, 1);
    CGContextBeginPath(ctx);
    CGContextAddLines(ctx, separator1, 3);
    CGContextStrokePath(ctx);
    CGContextSetStrokeColor(ctx, strokeComponents3);
    CGContextBeginPath(ctx);
    CGContextAddLines(ctx, separator2, 3);
    CGContextStrokePath(ctx);
    
    NSGraphicsContext *nsGraphicsContext;
    nsGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsGraphicsContext];
    NSString *title = [layer valueForKey:@"title"];
    [title drawAtPoint:CGPointMake(13, 7) withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"Helvetica-Bold",NSFontNameAttribute,@"16",NSFontSizeAttribute, nil]];
}

@end