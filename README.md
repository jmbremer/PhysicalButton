# PhysicalButton
A minimal wrapper around [jpsim/JPSVolumeButtonHandler](https://github.com/jpsim/JPSVolumeButtonHandler) for ease of use and to easily enable and disable the (sensitive) volume button handling more fine-grained

I'll add a bit of documentation when I get to that. For now see [my Stackoverflow answer](http://stackoverflow.com/a/37360733/893774).

Credit goes to the kind contributors of JPSVolumeButtonHandler, which does all the heavy lifting.

Notice some [issues](https://github.com/jpsim/JPSVolumeButtonHandler/issues/37) with volume levels that JPSVolumeButtonHandler seems to irrevocably affect.

Also notice that I occasionally end up with two instances of the underlying handler, when I/the user quits my app while physical button support is both enabled and on. This seems to have to do with some OS-internal notifications not being properly removed. There is nothing I can do about it in my wrapper. This is the description in my user guide, how to get things back to normal:

> In exceptional circumstance, the app may not get a chance to properly switch volume button handling off outside the Stopwatch view. This may be the case, for example, if you completely quit the app while a timing is in progress and physical button support is enabled. It may also happen, when you restart your iPhone, or when you use two timing apps with active physical button support at the same time such as this app and our smart ski & rally car timing app.
> 
> As a result, in the next timing, your iPhone may recognize a single volume button tap as multiple taps, generating multiple time records with a single tap of a volume button.
> 
> To get things back to normal,
> 1. Stop and reset any timing session in progress,
> 2. Switch off physical button support in the settings,
> 3. leave and completely terminate the app by double-tapping your iPhone's home button and swiping up to push the app out of the app list completely.
> Then restart the app.
> 
> If you recognize the problem only while an important timing is already in progress, delete the extra time record and use the virtual start/split button only for the remainder of this timing.


From Settings > User Guide > "Option: Physical Button Support" in [the next-generation sports stopwatch app](https://itunes.apple.com/app/herotime-smart-multi-stopwatch/id1072873744?mt=8) (see also [here](http://smartstopwatch.com) for more) - just in case you want to see how the wrapper is supposed to work in action.
