//
//  MGWUTimedResourceManager.h
//  MGWUTimedResourceManager
//
//  Created by Daniel Haaser on 7/12/14.
//  Copyright (c) 2014 MakeGamesWithUs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MGWUTimedResourceManager : NSObject

+ (instancetype) sharedManager;

// Maximum Value is the value at which the resource manager will stop scheduling increments and collections

- (NSInteger)getOrCreateTimedResourceWithKey:(NSString*)key
                                initialValue:(NSInteger)initialValue
                                maximumValue:(NSInteger)maxValue
                             incrementAmount:(NSInteger)incrementAmount
                      incrementTimeInSeconds:(NSTimeInterval)incrementTimeInSeconds
                                 autoCollect:(BOOL)autoCollect;

- (NSInteger)getValueForTimedResourceWithKey:(NSString*)key;

- (void)setValue:(NSInteger)value forTimedResourceWithKey:(NSString*)key;

- (NSTimeInterval)getSecondsLeftBeforeIncrementForTimedResourceWithKey:(NSString*)key;

- (NSInteger)getMaximumValueForTimedResourceWithKey:(NSString*)key;

- (NSInteger)getAmountOfResourceAvailableForCollectionWithKey:(NSString*)key;

- (void)collectResourceWithKey:(NSString*)key;

- (void)scheduleNotificationsForResourceWithKey:(NSString*)key andAlertBody:(NSString*)body;  //TODO: Alert action?

@end
