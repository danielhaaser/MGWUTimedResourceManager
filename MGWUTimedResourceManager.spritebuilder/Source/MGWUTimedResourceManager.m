//
//  MGWUTimedResourceManager.m
//  MGWUTimedResourceManager
//
//  Created by Daniel Haaser on 7/12/14.
//  Copyright (c) 2014 MakeGamesWithUs. All rights reserved.
//

#import "MGWUTimedResourceManager.h"
#import "NSUserDefaults+Encryption.h"

@implementation MGWUTimedResourceManager

static const NSString* VALUE_KEY = @"Value";
static const NSString* VALUE_AVAILABLE_TO_COLLECT_KEY = @"ValueAvailableToCollect";
static const NSString* MAX_VALUE_KEY = @"MaximumValue";
static const NSString* INCREMENT_AMOUNT_KEY = @"IncrementAmount";
static const NSString* INCREMENT_TIME_INTERVAL_KEY = @"IncrementTimeInterval";
static const NSString* DATE_VALUE_LAST_LESS_THAN_MAX_KEY = @"DateValueLastLessThanMax";
static const NSString* AUTO_COLLECT_KEY = @"AutoCollect";
static const NSString* NOTIFY_USER_KEY = @"NotifyUser";
static const NSString* NOTIFICATION_BODY_TEXT = @"BodyText";
static const NSString* NOTIFICATION_ALERT_TEXT = @"AlertText";
static const NSString* NOTIFICATION_ALERT_SOUND = @"AlertSound";

#pragma mark -
#pragma mark Lifecycle

+ (instancetype)sharedManager
{
    static dispatch_once_t once = 0;
    __strong static id sharedTimedResourceManager;
    dispatch_once(&once, ^
    {
        sharedTimedResourceManager = [[self alloc] init];
    });
    
    return sharedTimedResourceManager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [[NSUserDefaults standardUserDefaults] setEncryptionKey:[self generateEncryptionKey]];
    }
    
    return self;
}

// Generate the encryption key dynamically to make it harder to discover
// Replace this method with different random strings to make it more secure
// (Doing this will ensure that your encryption is different than any other app's encyption)
- (NSString*)generateEncryptionKey
{
    NSMutableString* randomString = [[[[[[[NSMutableString stringWithString:@"5E1E7"]
                                         stringByAppendingString:@"6932B"]
                                        stringByAppendingString:@"C1399"]
                                       stringByAppendingString:@"71454"]
                                      stringByAppendingString:@"8D711"]
                                     stringByAppendingString:@"3673U"] mutableCopy];
    
    [randomString replaceOccurrencesOfString:@"1" withString:@"E58H" options:NSLiteralSearch range:NSRangeFromString(randomString)];
    
    return randomString;
}

#pragma mark -
#pragma mark Public Methods

- (NSInteger)getOrCreateTimedResourceWithKey:(NSString*)key
                                initialValue:(NSInteger)initialValue
                                maximumValue:(NSInteger)maxValue
                             incrementAmount:(NSInteger)incrementAmount
                      incrementTimeInSeconds:(NSTimeInterval)incrementTimeInSeconds
                                 autoCollect:(BOOL)autoCollect
                                  notifyUser:(BOOL)notifyUser
{
    NSDictionary* resourceDictionary = [[NSUserDefaults standardUserDefaults] objectEncryptedForKey:key];
    
    if (!resourceDictionary)
    {
        NSDate* now = [NSDate date];
        
        // Create resource dictionary
        NSDictionary* newResourceDictionary = @{VALUE_KEY: @(initialValue),
                                                MAX_VALUE_KEY: @(maxValue),
                                                VALUE_AVAILABLE_TO_COLLECT_KEY: @(0),
                                                INCREMENT_AMOUNT_KEY: @(incrementAmount),
                                                INCREMENT_TIME_INTERVAL_KEY: @(incrementTimeInSeconds),
                                                DATE_VALUE_LAST_LESS_THAN_MAX_KEY: now,
                                                AUTO_COLLECT_KEY: @(autoCollect),
                                                NOTIFY_USER_KEY: @(notifyUser),
                                                NOTIFICATION_BODY_TEXT: @"",
                                                NOTIFICATION_ALERT_TEXT: @"",
                                                NOTIFICATION_ALERT_SOUND: @""};
        
        [[NSUserDefaults standardUserDefaults] setObjectEncrypted:newResourceDictionary forKey:key];
    }
    
    [self iterativelyAddResourceToCollectQueueWithKey:key];
    
    NSNumber* resourceValue = [resourceDictionary objectForKey:VALUE_KEY];
    return [resourceValue integerValue];
}


- (NSInteger)getValueForTimedResourceWithKey:(NSString*)key
{
    [self iterativelyAddResourceToCollectQueueWithKey:key];
    
    NSDictionary* resourceDictionary = [self getResourceDictionaryForKey:key];
    NSNumber* resourceValue = [resourceDictionary objectForKey:VALUE_KEY];
    return [resourceValue integerValue];
}

- (void)setValue:(NSInteger)value forTimedResourceWithKey:(NSString*)key
{
    NSMutableDictionary* resourceDictionary = [[self getResourceDictionaryForKey:key] mutableCopy];
    
    NSNumber* newValue = @(value);
    NSNumber* maxValue = [resourceDictionary objectForKey:MAX_VALUE_KEY];
    NSNumber* oldValue = [resourceDictionary objectForKey:VALUE_KEY];
    
    
    NSDate* dateValueLastLessThanMax = [resourceDictionary objectForKey:DATE_VALUE_LAST_LESS_THAN_MAX_KEY];
    NSTimeInterval timeIntervalSinceDateValueLastLessThanMax = [[NSDate date] timeIntervalSinceDate:dateValueLastLessThanMax];
    NSTimeInterval timeBetweenIncrements = [[resourceDictionary objectForKey:INCREMENT_TIME_INTERVAL_KEY] doubleValue];
    
    // If the new value is less than the old value,
    // reset the new collect date to now minus current countdown interval
    if ([newValue compare:oldValue] == NSOrderedAscending)
    {
        while (timeIntervalSinceDateValueLastLessThanMax > timeBetweenIncrements)
        {
            timeIntervalSinceDateValueLastLessThanMax -= timeBetweenIncrements;
        }
    }
    
    NSDate* newLastMaxReferenceDate = [NSDate dateWithTimeIntervalSinceNow:-1.0 * timeIntervalSinceDateValueLastLessThanMax];
    [resourceDictionary setObject:newLastMaxReferenceDate forKey:DATE_VALUE_LAST_LESS_THAN_MAX_KEY];
    
    // If the value was at maximum, and is now less: reset the date to start a new timer
    if (([oldValue compare:maxValue] != NSOrderedAscending)  && [newValue compare:oldValue] == NSOrderedAscending)
    {
        [resourceDictionary setObject:[NSDate date] forKey:DATE_VALUE_LAST_LESS_THAN_MAX_KEY];
    }
    
    [resourceDictionary setObject:newValue forKey:VALUE_KEY];
    [[NSUserDefaults standardUserDefaults] setObjectEncrypted:[NSDictionary dictionaryWithDictionary:resourceDictionary] forKey:key];
    
    [self scheduleLocalNotificationForResourceWithKey:key];
}

- (NSTimeInterval)getSecondsLeftBeforeIncrementForTimedResourceWithKey:(NSString*)key
{
    NSDictionary* resourceDictionary = [self getResourceDictionaryForKey:key];
    
    NSDate* dateValueLastLessThanMax = [resourceDictionary objectForKey:DATE_VALUE_LAST_LESS_THAN_MAX_KEY];
    
    NSTimeInterval timeIntervalSinceDateValueLastLessThanMax = [[NSDate date] timeIntervalSinceDate:dateValueLastLessThanMax];
    NSTimeInterval timeBetweenIncrements = [[resourceDictionary objectForKey:INCREMENT_TIME_INTERVAL_KEY] doubleValue];

    NSInteger uncollectedIncrements = [self getNumberOfUncollectedIncrementsElapsedForKey:key];
    
    NSTimeInterval result = (timeBetweenIncrements * (uncollectedIncrements + 1)) - timeIntervalSinceDateValueLastLessThanMax;
    
    NSInteger value = [[resourceDictionary objectForKey:VALUE_KEY] integerValue];
    NSInteger maximumValue = [[resourceDictionary objectForKey:MAX_VALUE_KEY] integerValue];
    NSInteger uncollectedValue = [[resourceDictionary objectForKey:VALUE_AVAILABLE_TO_COLLECT_KEY] integerValue];
    
    if (value + uncollectedValue < maximumValue)
    {
        return (result >= 0.0) ? result : 0.0;
    }
    else
    {
        return 0.0;
    }
}

- (NSInteger)getMaximumValueForTimedResourceWithKey:(NSString*)key
{
    NSDictionary* resourceDictionary = [self getResourceDictionaryForKey:key];
    NSNumber* maximumValue = [resourceDictionary objectForKey:MAX_VALUE_KEY];
    return [maximumValue integerValue];
}

- (void)collectResourceWithKey:(NSString*)key
{
    [self iterativelyAddResourceToCollectQueueWithKey:key];
    [self actuallyCollectValueWithKey:key];
}

- (NSInteger)getAmountOfResourceAvailableForCollectionWithKey:(NSString*)key
{
    [self iterativelyAddResourceToCollectQueueWithKey:key];
    
    NSDictionary* resourceDictionary = [self getResourceDictionaryForKey:key];
    NSNumber* resourcesAvailableToCollect = [resourceDictionary objectForKey:VALUE_AVAILABLE_TO_COLLECT_KEY];
    return [resourcesAvailableToCollect integerValue];
}

- (void)setNotificationBodyText:(NSString*)bodyText alertText:(NSString*)alertText andSound:(NSString*)soundFileName forKey:(NSString*)key
{
    NSMutableDictionary* resourceDictionary = [[self getResourceDictionaryForKey:key] mutableCopy];
    if (bodyText != nil) [resourceDictionary setObject:bodyText forKey:NOTIFICATION_BODY_TEXT];
    if (alertText != nil) [resourceDictionary setObject:alertText forKey:NOTIFICATION_ALERT_TEXT];
    if (soundFileName != nil) [resourceDictionary setObject:soundFileName forKey:NOTIFICATION_ALERT_SOUND];
    
    [[NSUserDefaults standardUserDefaults] setObjectEncrypted:[NSDictionary dictionaryWithDictionary:resourceDictionary] forKey:key];
}

#pragma mark -
#pragma mark Private Methods

#pragma mark Utility

- (NSDictionary*)getResourceDictionaryForKey:(NSString*)key
{
    NSDictionary* resourceDictionary = [[NSUserDefaults standardUserDefaults] objectEncryptedForKey:key];
    NSAssert(resourceDictionary != nil, @"Error - Resource does not exist or key is wrong. Did you create the resource with getOrCreateTimedResourceWithKey: ?");
    return resourceDictionary;
}

#pragma mark Collection

- (void)applyAutoCollectIfApplicableForKey:(NSString*)key
{
    NSDictionary* resourceDictionary = [self getResourceDictionaryForKey:key];
    
    BOOL autoCollect = [[resourceDictionary objectForKey:AUTO_COLLECT_KEY] boolValue];
    
    if (autoCollect)
    {
        [self actuallyCollectValueWithKey:key];
    }
}

- (void)iterativelyAddResourceToCollectQueueWithKey:(NSString*)key
{
    NSMutableDictionary* resourceDictionary = [[self getResourceDictionaryForKey:key] mutableCopy];
    
    NSDate* dateValueLastLessThanMax = [resourceDictionary objectForKey:DATE_VALUE_LAST_LESS_THAN_MAX_KEY];
    NSTimeInterval timeIntervalSinceDateValueLastLessThanMax = [[NSDate date] timeIntervalSinceDate:dateValueLastLessThanMax];
    NSTimeInterval timeBetweenIncrements = [[resourceDictionary objectForKey:INCREMENT_TIME_INTERVAL_KEY] doubleValue];
    
    NSInteger currentValue = [[resourceDictionary objectForKey:VALUE_KEY] integerValue];
    NSInteger maximumValue = [[resourceDictionary objectForKey:MAX_VALUE_KEY] integerValue];
    NSInteger incrementAmount = [[resourceDictionary objectForKey:INCREMENT_AMOUNT_KEY] integerValue];
    NSInteger valueAvailableToCollect = [[resourceDictionary objectForKey:VALUE_AVAILABLE_TO_COLLECT_KEY] integerValue];
    
    // While the value of the resource is less than maximum value
    // And we haven't yet surprassed the current date from the last "Value less than max" date
    // Continue incrementing
    BOOL dictionaryIsDirty = NO;
    while (valueAvailableToCollect + currentValue < maximumValue && timeIntervalSinceDateValueLastLessThanMax > timeBetweenIncrements)
    {
        valueAvailableToCollect += incrementAmount;
        
        if (valueAvailableToCollect + currentValue > maximumValue)
            valueAvailableToCollect = maximumValue - currentValue;
        
        timeIntervalSinceDateValueLastLessThanMax -= timeBetweenIncrements;
        
        dictionaryIsDirty = YES;
    }
    
    if (dictionaryIsDirty)
    {
        // Reset the reference date
        NSDate* newLastMaxReferenceDate = [NSDate dateWithTimeIntervalSinceNow:-1.0 * timeIntervalSinceDateValueLastLessThanMax];
        
        // Update dictionary with new values and place them back in encrypted user defaults
        [resourceDictionary setObject:@(currentValue) forKey:VALUE_KEY];
        [resourceDictionary setObject:@(valueAvailableToCollect) forKey:VALUE_AVAILABLE_TO_COLLECT_KEY];
        [resourceDictionary setObject:newLastMaxReferenceDate forKey:DATE_VALUE_LAST_LESS_THAN_MAX_KEY];
        
        [[NSUserDefaults standardUserDefaults] setObjectEncrypted:[NSDictionary dictionaryWithDictionary:resourceDictionary] forKey:key];
        
        [self scheduleLocalNotificationForResourceWithKey:key];
    }
    
    // Collect the resources if auto collect is on
    [self applyAutoCollectIfApplicableForKey:key];
}

- (void)actuallyCollectValueWithKey:(NSString*)key
{
    NSMutableDictionary* resourceDictionary = [[self getResourceDictionaryForKey:key] mutableCopy];
    
    NSInteger currentValue = [[resourceDictionary objectForKey:VALUE_KEY] integerValue];
    NSInteger maximumValue = [[resourceDictionary objectForKey:MAX_VALUE_KEY] integerValue];
    NSInteger valueAvailableToCollect = [[resourceDictionary objectForKey:VALUE_AVAILABLE_TO_COLLECT_KEY] integerValue];
    
    currentValue += valueAvailableToCollect;
    
    if (currentValue > maximumValue)
    {
        currentValue = maximumValue;
    }
    
    [resourceDictionary setObject:@(0) forKey:VALUE_AVAILABLE_TO_COLLECT_KEY];
    [resourceDictionary setObject:@(currentValue) forKey:VALUE_KEY];
    
    [[NSUserDefaults standardUserDefaults] setObjectEncrypted:[NSDictionary dictionaryWithDictionary:resourceDictionary] forKey:key];
}

- (NSInteger)getNumberOfUncollectedIncrementsElapsedForKey:(NSString*)key
{
    NSDictionary* resourceDictionary = [self getResourceDictionaryForKey:key];
    
    NSDate* dateValueLastLessThanMax = [resourceDictionary objectForKey:DATE_VALUE_LAST_LESS_THAN_MAX_KEY];
    NSTimeInterval timeIntervalSinceDateValueLastLessThanMax = [[NSDate date] timeIntervalSinceDate:dateValueLastLessThanMax];
    NSTimeInterval timeBetweenIncrements = [[resourceDictionary objectForKey:INCREMENT_TIME_INTERVAL_KEY] doubleValue];
    
    NSInteger currentValue = [[resourceDictionary objectForKey:VALUE_KEY] integerValue];
    NSInteger maximumValue = [[resourceDictionary objectForKey:MAX_VALUE_KEY] integerValue];
    NSInteger incrementAmount = [[resourceDictionary objectForKey:INCREMENT_AMOUNT_KEY] integerValue];
    
    NSInteger intervalCount = 0;
    while (currentValue < maximumValue && timeIntervalSinceDateValueLastLessThanMax > timeBetweenIncrements)
    {
        currentValue += incrementAmount;
        
        if (currentValue > maximumValue)
            currentValue = maximumValue;

        intervalCount++;
        timeIntervalSinceDateValueLastLessThanMax -= timeBetweenIncrements;
    }
    
    return intervalCount;
}

#pragma mark Notifications

- (void)scheduleLocalNotificationForResourceWithKey:(NSString*)key
{
    NSDictionary* resourceDictionary = [self getResourceDictionaryForKey:key];
    BOOL notifyUser = [[resourceDictionary objectForKey:NOTIFY_USER_KEY] boolValue];
    
    if (notifyUser)
    {
        BOOL autoCollect = [[resourceDictionary objectForKey:AUTO_COLLECT_KEY] boolValue];
        NSInteger incrementAmount = [[resourceDictionary objectForKey:INCREMENT_AMOUNT_KEY] integerValue];
        NSTimeInterval timeBeforeResourceAvailable = [self getSecondsLeftBeforeIncrementForTimedResourceWithKey:key];
        
        UILocalNotification* localNotification = [UILocalNotification new];
        
        if (localNotification == nil)
        {
            NSLog(@"MGWUTimedResourceManager Error - User notification not scheduled.");
            return;
        }
        
        localNotification.fireDate = [NSDate dateWithTimeInterval:timeBeforeResourceAvailable sinceDate:[NSDate date]];
        
        if (autoCollect)
        {
            localNotification.alertBody = [NSString stringWithFormat:@"Your %@ count has increased by %ld!", key, (long)incrementAmount];
            localNotification.alertAction = @"play";
        }
        else
        {
            localNotification.alertBody = [NSString stringWithFormat:@"Time to collect your %@!", key];
            localNotification.alertAction = @"collect!";
        }
        
        NSString* bodyText = [resourceDictionary objectForKey:NOTIFICATION_BODY_TEXT];
        NSString* alertText = [resourceDictionary objectForKey:NOTIFICATION_ALERT_TEXT];
        NSString* alertSound = [resourceDictionary objectForKey:NOTIFICATION_ALERT_SOUND];
        
        if (![bodyText isEqualToString:@""]) localNotification.alertBody = bodyText;
        if (![alertText isEqualToString:@""]) localNotification.alertAction = alertText;
        if (![alertSound isEqualToString:@""]) localNotification.soundName = alertSound;
        
        localNotification.applicationIconBadgeNumber = 1;
        localNotification.userInfo = @{@"Resource": key};
        
        // Unschedule all local notifications for this key
        [self unscheduleLocalNotificationsForKey:key];
        
        // Schedule the new local notification for this key
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

- (void)unscheduleLocalNotificationsForKey:(NSString*)key
{
    NSMutableArray* scheduledLocalNotifications = [[UIApplication sharedApplication].scheduledLocalNotifications mutableCopy];
    NSMutableArray* notificationsToRemove = [NSMutableArray array];
    
    for (UILocalNotification* notification in scheduledLocalNotifications)
    {
        NSDictionary* userInfo = notification.userInfo;
        NSString* resourceKey = [userInfo objectForKey:@"Resource"];
        if ([resourceKey isEqualToString:key])
        {
            [notificationsToRemove addObject:notification];
        }
    }
    
    for (UILocalNotification* notification in notificationsToRemove)
    {
        [scheduledLocalNotifications removeObject:notification];
    }
    
    [UIApplication sharedApplication].scheduledLocalNotifications = [NSArray arrayWithArray:scheduledLocalNotifications];
}

@end
