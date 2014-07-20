MGWUTimedResourceManager
========================

This class provides an interface to add timed resources to your game.  

Timed resources are scarce - they only regenerate after a certain amount of time has elapsed, like the lives in Candy Crush Saga and TwoDots.

```MGWUTimedResourceManager``` protects the value of these resources with encryption.  To do that, it uses ```NSUserDefaults+Encryption``` to work, so when adding this to your project, include both ```MGWUTimedResourceManager``` and ```NSUserDefaults+Encryption```.

Some games force the user to press a button to collect their earned resources, other don't.  This class supports both via the auto collect property.

## Properties

Each timed resource has some properties:

property | description
--- | ---
value | current value of the resource 
maximum value | maximum vaue the resource can increment to
increment amount | amount added to the value after an increment interval
increment interval | time in seconds between each increment 
auto collect | resources may be collected automatically, or may be collected only after the collect method is called
notify user | whether the user will receive a notification when the resource is added or ready to collect

## Notifications

```MGWUTimedResourceManager``` will try to generate notification text for you, but it's not very good.  Instead, use:

```objective-c
    setNotificationBodyText:(NSString*)bodyText alertText:(NSString*)alertText andSound:(NSString*)soundFileName forKey:(NSString*)key
```
 to set up your own notification text and sound.
 
 parameter | description
 --- | ---
 body text | the message the user sees in their notification
 alert text | the action verb - e.g. "swipe to *play*", "swipe to *collect*"
 alert sound | _(optional)_ path to a custom notification sound
 
### Badge Icon
 
 The notification will display a badge on your icon.  To clear this badge when the user enters your app, add this method to your ```AppDelegate.m```:
 
```objective-c
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
}
```

To make sure the badge isn't added while the user is actively in your app, also add this method to your ```AppDelegate.m```:
```objective-c
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    application.applicationIconBadgeNumber = 0;
}
```

## Security

To maximize the security of the encryption, change the string literals in the```- (NSString*)generateEncryptionKey``` method of ```MGWUTimedResourceManager.m``` to some other random values.
 
