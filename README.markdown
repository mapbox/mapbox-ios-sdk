MapBox iOS SDK
--------------

Based on the Route-Me iOS map library (Alpstein fork) with custom [MapBox][mapbox] additions. 

Requires iOS 5 and Xcode 4.3 or greater. Does not yet support ARC. 

Major differences from [Alpstein fork of Route-Me](https://github.com/Alpstein/route-me): 

 * Requires iOS 5.0 and above. 
 * [MapBox](http://mapbox.com) & [MBTiles](http://mbtiles.org) tile source integration code. 
 * [MapBox Markers](http://mapbox.com/blog/markers/) support. 
 * [UTFGrid interactivity](http://mapbox.com/mbtiles-spec/utfgrid/). 
 * Improved network tile loading performance. 
 * Prepackaged [binary framework](http://mapbox.com/blog/ios-sdk-framework/). 
 * [CocoaPods](http://cocoapods.org) support. 
 * Removal of two-finger double-tap gesture for zoom out (to speed up two-finger single-tap recognition like MapKit). 
 * Different default starting location for maps. 
 * Built-in attribution view controller with button on map views & default OpenStreetMap attribution. 
 * Removed of included example projects in favor of separate examples on GitHub. 
 * A few added defaults for convenience. 
 * Improved documentation. 

[mapbox]: http://mapbox.com

Route-Me
--------

Route-Me is an open source map library that runs natively on iOS.  It's designed to look and feel much like the built-in iOS map library, but it's entirely open, and works with any map source.

Currently, [OpenStreetMap][1], [OpenCycleMap][2], [OpenSeaMap][3], [MapQuest OSM][4], [MapQuest Open Aerial][5], [MapBox Hosting][6]/[TileStream][7], and two offline-capable, database-backed formats (DBMap and [MBTiles][8]) are supported as map sources.

Please note that you are responsible for getting permission to use the map data, and for ensuring your use adheres to the relevant terms of use.

   [1]: http://www.openstreetmap.org/index.html
   [2]: http://www.opencyclemap.org/
   [3]: http://www.openseamap.org/
   [4]: http://developer.mapquest.com/web/products/open/map
   [5]: http://developer.mapquest.com/web/products/open/map
   [6]: http://mapbox.com/hosting/api/
   [7]: https://github.com/mapbox/tilestream
   [8]: http://mbtiles.org

Installing
----------

There are three ways that you can install the SDK, depending upon your needs: 

 1. Clone from GitHub and integrate as a dependent Xcode project. 
 1. Use the [binary framework](https://github.com/mapbox/mapbox-ios-sdk/downloads). Use like regular frameworks, linking it in your project, adding `#import <MapBox/MapBox.h>`, and additionally, including the `-ObjC` linker flag. 
 1. Install via [CocoaPods](http://cocoapods.org). 

The two main branches of the GitHub repository are pretty self-explanatory: `release` and `develop`. When we tag a [release](https://github.com/mapbox/mapbox-ios-sdk/tags), we also merge `develop` over to `release`, except in the case of minor point releases (e.g., `0.4.2`), where we might just bring over a fix or two from `develop`. 

Then, update the submodules:

      git submodule update --init

Some example apps showing usage of the SDK:

 * [MapBox iOS Example](https://github.com/mapbox/mapbox-ios-example) - online, offline, and interactive tile sources
 * [MapBox Me](https://github.com/mapbox/mapbox-me) - user location services and terrain toggling
 * [Weekend Picks](https://github.com/mapbox/weekend-picks-template-ios) - markers and data

More documentation is available: 

      http://mapbox.com/mapbox-ios-sdk/

There are two subdirectories - MapView and Proj4. Proj4 is a support library used to do map projections. The MapView project contains only the Route-Me map library. 

See License.txt for license details. In any app that uses this SDK, include the following text on your "preferences" or "about" screen: "Uses MapBox iOS SDK, (c) 2008-2012 MapBox and Route-Me Contributors". Your data provider will have additional attribution requirements.

News, Support and Contributing
------------------------------

Complete API documentation is available [online][api] or as an [Xcode docset Atom feed][docset]. 

The MapBox iOS SDK has a [support resource][support] where you can open cases and browse other developers' discussions about use of the SDK. 

We have a [basic technical overview][docs] along with the installation instructions. 

MapBox has an IRC channel on `irc.freenode.net` in `#mapbox`. 

The main Route-Me project has a [mailing list][list] for news and to communicate with project members and other users. 

To report bugs and help fix them, please use the [issue tracker][tracker]. 

[api]: http://mapbox.com/mapbox-ios-sdk/api/
[docset]: http://mapbox.com/mapbox-ios-sdk/Docs/publish/docset.atom
[support]: http://support.mapbox.com/discussions/mapbox-ios-sdk
[docs]: http://mapbox.com/mobile/docs/sdk
[list]: http://groups.google.com/group/route-me-map
[tracker]: https://github.com/mapbox/mapbox-ios-sdk/issues
