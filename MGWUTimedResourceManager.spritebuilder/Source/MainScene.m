//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
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
    [[MGWUTimedResourceManager sharedManager] getOrCreateTimedResourceWithKey:@"Lives"
                                                                 initialValue:3
                                                                 maximumValue:5
                                                              incrementAmount:1
                                                       incrementTimeInSeconds:30.0
                                                                  autoCollect:NO];
    
    [[MGWUTimedResourceManager sharedManager] getOrCreateTimedResourceWithKey:@"Gems"
                                                                 initialValue:10
                                                                 maximumValue:100000
                                                              incrementAmount:5
                                                       incrementTimeInSeconds:45.0
                                                                  autoCollect:YES];
    
    [self schedule:@selector(updateLivesLabels) interval:1.0f];
    [self schedule:@selector(updateGemsLabels) interval:1.0f];
    [self updateLivesLabels];
    [self updateGemsLabels];
}

- (void)cleanup
{
    [self unschedule:@selector(updateLivesLabels)];
    [self unschedule:@selector(updateGemsLabels)];
}

#pragma mark -
#pragma mark Buttons

- (void)livesCollectPressed
{
    [[MGWUTimedResourceManager sharedManager] collectResourceWithKey:@"Lives"];
    [self updateLivesLabels];
}

- (void)livesBuyPressed
{
    NSInteger maximumLives = [[MGWUTimedResourceManager sharedManager] getMaximumValueForTimedResourceWithKey:@"Lives"];
    [[MGWUTimedResourceManager sharedManager] setValue:maximumLives forTimedResourceWithKey:@"Lives"];
}

- (void)lifeLostPressed
{
    NSInteger lives = [[MGWUTimedResourceManager sharedManager] getValueForTimedResourceWithKey:@"Lives"];
    lives--;
    [[MGWUTimedResourceManager sharedManager] setValue:(lives >= 0) ? lives : 0 forTimedResourceWithKey:@"Lives"];
    [self updateLivesLabels];
}

- (void)gemsBuyPressed
{
    NSInteger gems = [[MGWUTimedResourceManager sharedManager] getValueForTimedResourceWithKey:@"Gems"];
    gems += 100;
    [[MGWUTimedResourceManager sharedManager] setValue:gems forTimedResourceWithKey:@"Gems"];
    [self updateGemsLabels];
}

- (void)gemUsedPressed
{
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
                                
- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}


@end
