//
//  UIAccessibilityElement-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/23/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "NSPredicate+KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "UIApplication-KIFAdditions.h"
#import "UIScrollView-KIFAdditions.h"
#import "UIView-KIFAdditions.h"
#import "LoadableCategory.h"

MAKE_CATEGORIES_LOADABLE(UIAccessibilityElement_KIFAdditions)


@implementation UIAccessibilityElement (KIFAdditions)

+ (UIView *)viewContainingAccessibilityElement:(UIAccessibilityElement *)element;
{
    while (element && ![element isKindOfClass:[UIView class]]) {
        // Sometimes accessibilityContainer will return a view that's too far up the view hierarchy
        // UIAccessibilityElement instances will sometimes respond to view, so try to use that and then fall back to accessibilityContainer
        id view = [element respondsToSelector:@selector(view)] ? [(id)element view] : nil;
        
        if (view) {
            element = view;
        } else {
            element = [element accessibilityContainer];
        }
    }
    
    return (UIView *)element;
}

+ (BOOL)accessibilityElement:(out UIAccessibilityElement **)foundElement view:(out UIView **)foundView withLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable error:(out NSError **)error;
{
    UIAccessibilityElement *element = [self accessibilityElementWithLabel:label value:value traits:traits error:error];
    if (!element) {
        return NO;
    }
    
    UIView *view = [self viewContainingAccessibilityElement:element tappable:mustBeTappable error:error];
    if (!view) {
        return NO;
    }
    
    if (foundElement) { *foundElement = element; }
    if (foundView) { *foundView = view; }
    return YES;
}

+ (BOOL)accessibilityElement:(out UIAccessibilityElement **)foundElement view:(out UIView **)foundView withElementMatchingPredicate:(NSPredicate *)predicate tappable:(BOOL)mustBeTappable error:(out NSError **)error;
{
    UIAccessibilityElement *element = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:^BOOL(UIAccessibilityElement *element) {
        return [predicate evaluateWithObject:element];
    }];
    
    if (!element) {
        return NO;
    }
    
    UIView *view = [UIAccessibilityElement viewContainingAccessibilityElement:element tappable:mustBeTappable error:error];
    if (!view) {
        return NO;
    }
    
    if (foundElement) { *foundElement = element; }
    if (foundView) { *foundView = view; }
    return YES;
}

+ (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits error:(out NSError **)error;
{
    UIAccessibilityElement *element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:value traits:traits];
    if (element || !error) {
        return element;
    }
    
    element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:nil traits:traits];
    // For purposes of a better error message, see if we can find the view, just not a view with the specified value.
    if (value && element) {
        return nil;
    }
    
    // Check the traits, too.
    element = [[UIApplication sharedApplication] accessibilityElementWithLabel:label accessibilityValue:nil traits:UIAccessibilityTraitNone];
    if (traits != UIAccessibilityTraitNone && element) {
        return nil;
    }
    
    return nil;
}

+ (UIView *)viewContainingAccessibilityElement:(UIAccessibilityElement *)element tappable:(BOOL)mustBeTappable error:(NSError **)error;
{
    // Small safety mechanism.  If someone calls this method after a failing call to accessibilityElementWithLabel:..., we don't want to wipe out the error message.
    if (!element && error && *error) {
        return nil;
    }
    
    // Make sure the element is visible
    UIView *view = [UIAccessibilityElement viewContainingAccessibilityElement:element];
    if (!view) {
        if (error) {
        }
        return nil;
    }
    
    // Scroll the view (and superviews) to be visible if necessary
    UIView *superview = (UIScrollView *)view;
    while (superview) {
        // Fix for iOS7 table view cells containing scroll views
        if ([superview.superview isKindOfClass:[UITableViewCell class]]) {
            break;
        }
        
        if ([superview isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)superview;
            
            if (((UIAccessibilityElement *)view == element) && ![view isKindOfClass:[UITableViewCell class]]) {
                [scrollView scrollViewToVisible:view animated:YES];
            } else {
                CGRect elementFrame = [view.window convertRect:element.accessibilityFrame toView:scrollView];
                CGRect visibleRect = CGRectMake(scrollView.contentOffset.x, scrollView.contentOffset.y, CGRectGetWidth(scrollView.bounds), CGRectGetHeight(scrollView.bounds));
                
                // Only call scrollRectToVisible if the element isn't already visible
                // iOS 8 will sometimes incorrectly scroll table views so the element scrolls out of view
                if (!CGRectContainsRect(visibleRect, elementFrame)) {
                    [scrollView scrollRectToVisible:elementFrame animated:YES];
                }
            }
            
            // Give the scroll view a small amount of time to perform the scroll.
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.3, false);
        }
        
        superview = superview.superview;
    }
    
    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        return nil;
    }
    
    // If we don't require tappability, at least make sure it's not hidden
    if ([view isHidden]) {
        return nil;
    }
    
    if (mustBeTappable && !view.isProbablyTappable) {
        return nil;
    }
    
    return view;
}

+ (NSPredicate *)findClosestMatchingPredicate:(NSPredicate *)aPredicate;
{
    if (!aPredicate) {
        return nil;
    }
    
    UIAccessibilityElement *match = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:^BOOL (UIAccessibilityElement *element) {
        return [aPredicate evaluateWithObject:element];
    }];
    if (match) {
        return aPredicate;
    }
    
    // Breadth-First algorithm to match as many subpredicates as possible
    NSMutableArray *queue = [NSMutableArray arrayWithObject:aPredicate];
    while (queue.count > 0) {
        // Dequeuing
        NSPredicate *predicate = [queue firstObject];
        [queue removeObject:predicate];
        
        // Remove one subpredicate at a time an then check if an element would match this resulting predicate
        for (NSPredicate *subpredicate in [predicate flatten]) {
            NSPredicate *predicateMinusOneCondition = [predicate minusSubpredicatesFrom:subpredicate];
            if (predicateMinusOneCondition) {
                UIAccessibilityElement *match = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:^BOOL (UIAccessibilityElement *element) {
                    return [predicateMinusOneCondition evaluateWithObject:element];
                }];
                if (match) {
                    return predicateMinusOneCondition;
                }
                [queue addObject:predicateMinusOneCondition];
            }
        }
    }
    return nil;
}

+ (NSString *)stringFromAccessibilityTraits:(UIAccessibilityTraits)traits;
{
    if (traits == UIAccessibilityTraitNone) {
        return  @"UIAccessibilityTraitNone";
    }
    
    NSString *string = @"";
    
    NSArray *allTraits = @[
                           @(UIAccessibilityTraitButton),
                           @(UIAccessibilityTraitLink),
                           @(UIAccessibilityTraitHeader),
                           @(UIAccessibilityTraitSearchField),
                           @(UIAccessibilityTraitImage),
                           @(UIAccessibilityTraitSelected),
                           @(UIAccessibilityTraitPlaysSound),
                           @(UIAccessibilityTraitKeyboardKey),
                           @(UIAccessibilityTraitStaticText),
                           @(UIAccessibilityTraitSummaryElement),
                           @(UIAccessibilityTraitNotEnabled),
                           @(UIAccessibilityTraitUpdatesFrequently),
                           @(UIAccessibilityTraitStartsMediaSession),
                           @(UIAccessibilityTraitAdjustable),
                           @(UIAccessibilityTraitAllowsDirectInteraction),
                           @(UIAccessibilityTraitCausesPageTurn)
                           ];
    
    NSArray *traitNames = @[
                            @"UIAccessibilityTraitButton",
                            @"UIAccessibilityTraitLink",
                            @"UIAccessibilityTraitHeader",
                            @"UIAccessibilityTraitSearchField",
                            @"UIAccessibilityTraitImage",
                            @"UIAccessibilityTraitSelected",
                            @"UIAccessibilityTraitPlaysSound",
                            @"UIAccessibilityTraitKeyboardKey",
                            @"UIAccessibilityTraitStaticText",
                            @"UIAccessibilityTraitSummaryElement",
                            @"UIAccessibilityTraitNotEnabled",
                            @"UIAccessibilityTraitUpdatesFrequently",
                            @"UIAccessibilityTraitStartsMediaSession",
                            @"UIAccessibilityTraitAdjustable",
                            @"UIAccessibilityTraitAllowsDirectInteraction",
                            @"UIAccessibilityTraitCausesPageTurn"
                            ];
                            
    
    for (NSNumber *trait in allTraits) {
        if ((traits & trait.longLongValue) == trait.longLongValue) {
            NSString *name = [traitNames objectAtIndex:[allTraits indexOfObject:trait]];
            if (string.length > 0) {
                string = [string stringByAppendingString:@", "];
            }
            string = [string stringByAppendingString:name];
            traits &= ~trait.longLongValue;
        }
    }
    if (traits != UIAccessibilityTraitNone) {
        if (string.length > 0) {
            string = [string stringByAppendingString:@", "];
        }
        string = [string stringByAppendingFormat:@"UNKNOWN ACCESSIBILITY TRAIT: %llu", traits];
    }
    return string;
}

@end
