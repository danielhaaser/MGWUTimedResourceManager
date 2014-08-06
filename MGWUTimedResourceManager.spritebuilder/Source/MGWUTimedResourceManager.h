//
//  MGWUTimedResourceManager.h
//  MGWUTimedResourceManager
//
//  Created by Daniel Haaser on 7/12/14.
//  Copyright (c) 2014 MakeGamesWithUs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGWUTimedResourceManager : NSObject

/**
    Returns the shared instance of MGWUTimedResourceManager
 */
+ (instancetype) sharedManager;

/**
    If you've already created a timed resource with this key, this will return the value of that timed resource.
    Otherwise, it will create a new one for you.
    Maximum value is the largest the value the resource can assume from timed increments.
    Increment amount is the amount added to the resource after the increment time has elapsed.
    Increment time is the time interval between increments, set in seconds.
    If autoCollect is set to YES, then the increment amount will be immediately added to the value of the resource.
    If autoCollect is set to NO, then the increment amount will have to be collected, via the "collectResourceWithKey" method to add it to the value.
    If notifyUser is set to YES, then the user will receive a notification the next time a resource has been incremented.
    This class provides default notification text, but it's not very good.  To set your own notification text and sounds, use the setNotificationBodyText method.
 */
- (NSInteger)getOrCreateTimedResourceWithKey:(NSString*)key
                                initialValue:(NSInteger)initialValue
                                maximumValue:(NSInteger)maxValue
                             incrementAmount:(NSInteger)incrementAmount
                      incrementTimeInSeconds:(NSTimeInterval)incrementTimeInSeconds
                                 autoCollect:(BOOL)autoCollect
                                  notifyUser:(BOOL)notifyUser;

/**
    Returns the current value of the timed resource with the given key.
 */
- (NSInteger)getValueForTimedResourceWithKey:(NSString*)key;

/**
    Sets the current value of the timed resource with the given key.
    If this value is greater than or equal to the maximum value, then the timed resource will stop incrementing.
    Once it drops below the maximum value, it will resume incrementing.
 */
- (void)setValue:(NSInteger)value forTimedResourceWithKey:(NSString*)key;

/**
    Returns the seconds left before the resource with the given key increments.
    The returned value is 0.0 if the resource is not incrementing because it is greater than or equal to its maximum value.
 */
- (NSTimeInterval)getSecondsLeftBeforeIncrementForTimedResourceWithKey:(NSString*)key;

/**
    Returns the maximum value that the resource can assume before it will stop incrementing.
 */
- (NSInteger)getMaximumValueForTimedResourceWithKey:(NSString*)key;

/**
    If autoCollect is set to NO, this returns the amount of resources available to collect
 */
- (NSInteger)getAmountOfResourceAvailableForCollectionWithKey:(NSString*)key;

/**
    Adds the resources waiting to be collected to the value of the timed resource.
 */
- (void)collectResourceWithKey:(NSString*)key;

/**
    Change the text the user sees when you notify them that their resource has been incremented.
    The body text is the main text of the notification.
    The alert text is an action that will be displayed in the notification. For example: slide to "play" or slide to "collect".
    The sound filename is an optional path to a sound that will be played with the alert.  Sounds cannot be more than 30 seconds long.
    To use the default settings for any of these parameters, you can pass nil.
 */
- (void)setNotificationBodyText:(NSString*)bodyText alertText:(NSString*)alertText andSound:(NSString*)soundFileName forKey:(NSString*)key;

/**
    When set to true, a notification will be scheduled for when the timed resource hits the maximum value.
 */
- (void)notifyUserOnMaximum:(BOOL)notifyOnMax forTimedResourceWithKey:(NSString*)key;

@end
