MGWUTimedResourceManager
========================

This class provides an interface to add timed resources to your game.  
Timed resources are scarce - they only regenerate after a certain amount of time has elapsed, like the lives in Candy Crush Saga and TwoDots.

MGWUTimedResourceManager is dependent on NSUserDefaults+Encryption to work, so when adding this to your project, include both MGWUTimedResourceManager(.h + .m) and NSUserDefaults+Encryption(.h + .m).

