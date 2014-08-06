//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Daniel Haaser on 07/12/14.
//  Copyright (c) 2013 MakeGamesWithUs. All rights reserved.
//

#import "MainScene.h"
#import "MGWUTimedResourceManager.h"

@implementation MainScene
{
    CCLabelTTF* lblLives;
    CCLabelTTF* lblGems;
    CCLabelTTF* lblLivesCountdown;
    CCLabelTTF* lblGemsCountdown;
}

#pragma mark -
#pragma mark Lifecycle

- (void)didLoadFromCCB
{
    //  Create a lives timed resource that must be collected to get added
    [[MGWUTimedResourceManager sharedManager] getOrCreateTimedResourceWithKey:@"Lives"
                                                                 initialValue:3
                                                                 maximumValue:5
                                                              incrementAmount:1
                                                       incrementTimeInSeconds:30.0
                                                                  autoCollect:NO
                                                                   notifyUser:YES];
    
    [[MGWUTimedResourceManager sharedManager] notifyUserOnMaximum:YES forTimedResourceWithKey:@"Lives"];

    
    //  Create a gems timed resource that is automatically added
    [[MGWUTimedResourceManager sharedManager] getOrCreateTimedResourceWithKey:@"Gems"
                                                                 initialValue:10
                                                                 maximumValue:500
                                                              incrementAmount:5
                                                       incrementTimeInSeconds:45.0
                                                                  autoCollect:YES
                                                                   notifyUser:YES];
    
    //  Set custom life notification text
    [[MGWUTimedResourceManager sharedManager] setNotificationBodyText:@"You have an extra life waiting to be collected!"
                                                            alertText:@"collect"
                                                             andSound:@"Published-iOS/sounds/lifeUp.caf"
                                                               forKey:@"Lives"];
    
    //  Set custom gems notification text
    [[MGWUTimedResourceManager sharedManager] setNotificationBodyText:@"You just earned 10 more gems!"
                                                            alertText:@"play"
                                                             andSound:@"Published-iOS/sounds/gemPing.caf"
                                                               forKey:@"Gems"];
    
    [self schedule:@selector(updateLivesLabels) interval:1.0f];
    [self schedule:@selector(updateGemsLabels) interval:1.0f];
    [self updateLivesLabels];
    [self updateGemsLabels];
}

- (void)onExit
{
    [self unschedule:@selector(updateLivesLabels)];
    [self unschedule:@selector(updateGemsLabels)];
    
    [super onExit];
}

#pragma mark -
#pragma mark Buttons

- (void)livesCollectPressed
{
    //  Collect the available lives
    [[MGWUTimedResourceManager sharedManager] collectResourceWithKey:@"Lives"];
    [self updateLivesLabels];
}

- (void)livesBuyPressed
{
    // If they buy the lives pack, max out thier lives
    NSInteger maximumLives = [[MGWUTimedResourceManager sharedManager] getMaximumValueForTimedResourceWithKey:@"Lives"];
    [[MGWUTimedResourceManager sharedManager] setValue:maximumLives forTimedResourceWithKey:@"Lives"];
}

- (void)lifeLostPressed
{
    // Oh no, the user screwed up and lost a life!
    NSInteger lives = [[MGWUTimedResourceManager sharedManager] getValueForTimedResourceWithKey:@"Lives"];
    lives--;
    [[MGWUTimedResourceManager sharedManager] setValue:(lives >= 0) ? lives : 0 forTimedResourceWithKey:@"Lives"];
    [self updateLivesLabels];
}

- (void)gemsBuyPressed
{
    // Add 100 gems for buying the gems pack
    NSInteger gems = [[MGWUTimedResourceManager sharedManager] getValueForTimedResourceWithKey:@"Gems"];
    gems += 100;
    [[MGWUTimedResourceManager sharedManager] setValue:gems forTimedResourceWithKey:@"Gems"];
    [self updateGemsLabels];
}

- (void)gemUsedPressed
{
    //  Spend 10 gems per use
    NSInteger gems = [[MGWUTimedResourceManager sharedManager] getValueForTimedResourceWithKey:@"Gems"];
    gems -= 10;
    [[MGWUTimedResourceManager sharedManager] setValue:(gems >= 0) ? gems : 0 forTimedResourceWithKey:@"Gems"];
}

#pragma mark -
#pragma mark Labels

- (void)updateLivesLabels
{
    NSTimeInterval livesCountdownTime = [[MGWUTimedResourceManager sharedManager] getSecondsLeftBeforeIncrementForTimedResourceWithKey:@"Lives"];
    NSString* livesCountdownTimeFormatted = [self stringFromTimeInterval:livesCountdownTime];
    NSInteger livesAvailableToCollect = [[MGWUTimedResourceManager sharedManager] getAmountOfResourceAvailableForCollectionWithKey:@"Lives"];
    lblLivesCountdown.string = [NSString stringWithFormat:@"%@ \n(%ld available to collect)", livesCountdownTimeFormatted, (long)livesAvailableToCollect];
    
    
    NSInteger lives = [[MGWUTimedResourceManager sharedManager] getValueForTimedResourceWithKey:@"Lives"];
    NSInteger maximumLives = [[MGWUTimedResourceManager sharedManager] getMaximumValueForTimedResourceWithKey:@"Lives"];
    lblLives.string = [NSString stringWithFormat:@"LIVES: %ld/%ld", (long) lives, (long) maximumLives];
}

- (void)updateGemsLabels
{
    NSTimeInterval gemsCountdownTime = [[MGWUTimedResourceManager sharedManager] getSecondsLeftBeforeIncrementForTimedResourceWithKey:@"Gems"];
    NSString* gemsCountdownTimeFormatted = [self stringFromTimeInterval:gemsCountdownTime];
    lblGemsCountdown.string = [NSString stringWithFormat:@"%@", gemsCountdownTimeFormatted];
    
    NSInteger gems = [[MGWUTimedResourceManager sharedManager] getValueForTimedResourceWithKey:@"Gems"];
    lblGems.string = [NSString stringWithFormat:@"GEMS: %ld", (long) gems];
}
                                
#pragma mark -
#pragma mark Utility Methods
                                
- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval
{
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}


@end
