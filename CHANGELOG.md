Changelog
---------

### 1.6.1
#### April 25, 2015

  - Allow requirement for iOS 8 location services to be satisified both "always" and "when in use" modes. 
  - Fixed a bug when checking the types of tile sources that can be taken offline. 
  - Better developer warnings around when a Mapbox access token is required. 
  - Fixed a visual glitch with the user location dot. 
  - Improvements and fixes to CocoaPods installation method. 

### 1.6.0
#### February 4, 2015

  - Removed support for Mapbox `v3` API and require [access tokens](https://www.mapbox.com/developers/api/#access-tokens). 
  - Fixed a small bug with database caching which was also causing an error in the console log. 
  - Reduced console log verbosity. 
  - Deprecated the `-[RMMapboxSource init]` convenience initializer since tokens are now required. 
  - Updated the included GRMustache from 6.8.3 to 7.3.0. 
  - Documentation improvements. 

### 1.5.1
#### January 28, 2015

  - Deprecated `+[RMConfiguration configuration]` in favor of the Swift-friendly and better-looking `+[RMConfiguration sharedInstance]`. 
  - Fixed a bug in the docs removal script. 
  - Documentation improvements. 

### 1.5.0
#### January 16, 2015

  - Re-added support for Mapbox `v4` API and [access tokens](https://www.mapbox.com/developers/api/#access-tokens) (removed temporarily in `1.4.0`), which are required for new accounts. 
  - Added support for iOS 8's QoS on background network requests. 
  - Improved error handling. 
  - Improved localization support. 
  - Improved deprecation notification on some previously-removed API. 
  - A map view's `-setCenterCoordinate:` is no longer animated by default. 
  - Fixed an Auto Layout bug. 
  - Fixed some memory leaks. 
  - Performance improvements, especially to background downloading for offline use and to general disk caching. 
  - Clarified that only web-based tile sources are eligible for background downloading. 
  - Documentation improvements. 

### 1.4.1
#### September 5, 2014

  - Properly deprecated `-[RMMapView orderMarkersByYPosition]` and `-[RMMapView orderClusterMarkersAboveOthers]`. 

### 1.4.0
#### September 4, 2014

  - Temporarily removed support for Mapbox `v4` API and [access tokens](https://www.mapbox.com/developers/api/#access-tokens) in tile and metadata requests. 
  - Added a new `-[RMMapViewDelegate annotationSortingComparatorForMapView:]` callback allowing customization of annotation layer stacking order. This deprecates `-[RMMapView orderMarkersByYPosition]` and `-[RMMapView orderClusterMarkersAboveOthers]`. 
  - Fixed a bug with tile source initialization in `-viewDidLoad` and/or from storyboards. 
  - Better enforce proper `RMGreatCircleAnnotation` initialization. 
  - Fixed a memory leak in `RMShape`. 
  - Fixed a bug with drawing of `RMPolygonAnnotation` interior polygons. 
  - Documentation fixes. 

### 1.3.0
#### August 14, 2014

  - Added support for Mapbox `v4` API and [access tokens](https://www.mapbox.com/developers/api/#access-tokens) in tile and metadata requests. 
  - Now ensures that all Mapbox API requests are over HTTPS.   
  - Updated FMDB SQLite library under the hood for caching and MBTiles support. 
  - Updated some support for the forthcoming iOS 8. 
  - Fixed a crash that could occur when the map view delegate changed `showsUserLocation`. 
  - Fixes a minor bug with map view subview constraints during use of tab bar controllers. 
  - Fixed a minor memory leak with Grand Central Dispatch queues. 
  - Fixed a small deployment problem for iOS 5. 
  - Quieted some debug logging. 

### 1.2.0
#### June 23, 2014

  - Added an `RMGreatCircleAnnotation` class for geodesic polylines. 
  - Allow for additional touch gesture padding around thin `RMShape` layers. 
  - Added an `RMTileCache` method for retrieving anticipated raster tile background download counts for a given coverage area. 
  - Added some documentation to the now-supported `RMCompositeSource` for client-side raster tile compositing.
  - Upgraded SMCalloutView with updated iOS 7+ support. 
  - No longer allow callouts on non-marker annotation layers.
  - Minor fix to center coordinate/zoom level animation method. 
  - Use magnetic heading if true heading isn't accurate. 
  - Added a debug log when using the default watermarked map style. 
  - Updated some syntax to the newer boxed literals. 
  - Removed some compiler flags that would over-optimize and make debugging difficult. 
  - Made some improvements to the map view long-press gesture. 
  - Fixed an issue with certain tile sources having wrong tile image request methods called. 
  - Fixed some issues with the SQLite-backed tile cache not reclaiming freed disk space. 
  - Fixed some retain cycle memory use bugs.
  - Fixed a bug when toggling the logo bug and attribution button. 
  - Fixed a crash when trying to add invalid annotations. 
  - Fixed a bug with `RMStaticMapView` always using the default map style. 

### 1.1.0
#### January 2, 2014

  - Updated for iOS 7, including visual appearance, tint color behavior, modal presentation paradigms, deprecations, and addition of a compass button when in tracking mode. 
  - 64-bit compliance. 
  - Requires Xcode 5.0+. 
  - Revamped annotation drag & drop system to work more like MapKit's. 
  - Improved autolayout support, including iOS 7 `UIViewController` layout guides. 
  - Support for [auto-retina mode](/developers/api/#Image.quality.&.scale) for Mapbox OpenStreetMap-based maps. 
  - Added `-[RMMapView setAlpha:forTileSource:]` and `-[RMMapView setAlpha:forTileSourceAtIndex:]`. 
  - Added `RMCircleAnnotation`. 
  - Added `-[RMMBTilesSource initWithTileSetResource:]` convenience method. 
  - Added `-[RMPointAnnotation image]`. 
  - Changed default `RMMarker` image from a pin with a star to a blank pin. 
  - Updated `RMCircle` default alpha from `1.0` to `0.25` and line width from `10.0` to `2.0`. 
  - Enhanced customizability for point, polyline, and polygon annotations. 
  - Improvements to `RMUserTrackingBarButtonItem` state animations. 
  - More accurate tile background loading grid for iOS 6+. 
  - Renamed instances of *MapBox* to *Mapbox* to better reflect branding. 
  - Fixed several crashes related to XIB unarchiving, invalid `frame` passing, and offline use. 
  - More efficient `RMPointAnnotation` redraws. 
  - Raise an exception when bad parameters are passed to background caching instead of failing silently. 
  - Background cache delegate methods are now truly optional as specified in the `RMTileCacheBackgroundDelegate` protocol. 
  - Updated [GRMustache](https://github.com/groue/GRMustache) from `v5.4.3` to `v6.8.3`. 
  - Updated usage of `instancetype` and `typedef enum`. 
  - Clarified documentation. 
  - Improved and updated CocoaPods specification. 
  - Fixed some build warnings. 
  - Minor bug fixes. 

### 1.0.3
#### June 28, 2013

  - Added support for the new SSL tile API. 
  - Improved disk caching API. 
  - Updated some API URLs to the latest preferred versions. 
  - Made some documentation improvements. 
  - Fixed a bug with MapBox markers that used custom colors. 
  - Fixed several small potental crash bugs. 

### 1.0.2
#### March 29, 2013

  - Added locally-bundled metadata for basic `RMMapBoxSource` use so that apps can better work offline from first launch, including when using XIBs and storyboards. 
  - Added a `fillPatternImage` property to `RMShape` and `RMCircle`. 
  - Fixed a bug related to updating annotation clusters after removal of single annotations. 
  - Fixed a bug related to comparisons of projected points on the map. 

### 1.0.1
#### March 5, 2013

  - Fixed a bug with `RMMapViewDelegate` callbacks for post-move and zoom events. 

### 1.0.0
#### March 4, 2013

  - Support for Automatic Reference Counting (ARC) for easier memory management. 
  - Added delegate callbacks for annotation selection & deselection notification. 
  - Improved documentation, especially for offline tile caching. 
  - Added a new [code examples gallery](../examples). 
  - Added a long press gesture recognizer for annotation layers. 
  - Added an API for setting an SDK-wide custom user-agent string for network requests. 
  - Added a convenience method for MBTiles tile sources to more easily find them in your app's bundle. 
  - Allow selection of a `nil` annotation in order to deselect the current annotation. 
  - Added an API for clearing MapBox marker local caching. 
  - Map views now default to a watermarked MapBox Streets map instead of OpenStreetMap. 
  - User location accuracy circle now bounces when first homing in on coordinate. 
  - Compass heading path now adjusts width based on heading accuracy reading. 
  - Annotation clustering API is now much simpler and easier to use. 
  - Privatized some header files to reduce clutter during Xcode autocompletion. 
  - Latest upstream improvements, including constraints, annotation z-ordering, and bounding box fixes. 
  - Code cleanups, consistency tweaks, and bug fixes. 

### 0.5.2
#### January 3, 2013

  - Added support for programmatic selection of annotations and display of callouts. 
  - Added support for annotation `calloutOffset` like MapKit. 
  - Fixed some bugs with callouts on circles and other shapes. 
  - Better shape hit detection based on current `fillRule`. 
  - Fixed a bug with shape clipping when map views were inset from the top of their superview. 
  - Fixed a few memory reuse problems. 
  - Allow silent re-add of already-added annotations. 

### 0.5.1
#### December 12, 2012

  - Added support for annotation callout subtitles. 
  - Fixed a bug related to touch events in `UIControl` objects on the map view. 
  - Fixed a bug with Bézier shape drawing on iOS 5. 
  - Fixed a crash when passing a `nil` static map completion handler. 
  - Added a CocoaPods `Podspec` directly to the repository for development use. 
  - Corrected annotation layer delegate request behavior when using simplestyle. 

###  0.5.0
#### November 29, 2012

  - Added a background tile downloader for pre-caching maps. 
  - Added some annotation convenience classes for simple use cases. 
  - Added annotation callouts that behave like MapKit. 
  - Support for MapBox map ID alongside TileJSON for easier map tile source use.
  - Support for the MapBox image quality API to save bandwidth.
  - Improved Interface Builder support for `RMMapView` and `RMUserTrackingBarButtonItem`.
  - New `RMStaticMapView` class for creating `UIImageView`-like one-shot map images.
  - New `RMTileMillSource` tile source for developing directly off of a TileMill instance.
  - Methods for animated map zooming without changing map center as well as zoom/center changes in one step.
  - Support for individual annotation touch enabling/disabling with the enabled property.
  - Support for Bézier curves in shape layers.
  - Improved tile cache API to allow greater flexibility with selective cache clearing.
  - Easier attribution of map tile source data in the map view.
  - MapKit-like support for a custom user location annotation layer.
  - New `RMCompositeSource` tile source to enabling caching of client-side composited map tile end products.
  - Unified `MapBox.h` header with commonly-used classes for all install methods.
  - Updated GRMustache library for more up-to-date Mustache template functionality in UTFGrid interactivity.
  - SDK resources such as images now install in a single `MapBox.bundle` file instead of individually.
  - Removed the dependent build of the Proj4 projection library to greatly speed up compilation time.
  - Improvements to asynchronous map tile render speed and reliability.
  - Improved z-index sorting of cluster, point, and shape annotation layers.
  - Cleaned and reorganized Xcode project groups for simplicity.

### 0.4.3
#### September 17, 2012

  - Fixed a bug related to hiding & showing of the user location halo. 

### 0.4.2
#### September 5, 2012

  - Fixed a bug related to over-aggressive tile rendering for local tile sources. 

### 0.4.1
#### August 27, 2012

  - Fixed a bug related to app location services permission changes. 

### 0.4.0
#### August 23, 2012

  - First release in CocoaPods. 
  - First release of Xcode documentation. 
  - Improved the performance of network tile fetching and drawing.
  - Added retina support for MapBox markers.
  - Added the ability to reload individual composited tile sources.
  - The map view background now behaves more like MapKit when loading tiles.
  - Added a single, unified header file for easier project inclusion.
  - The map view is no longer recreated on tile source reordering or hiding.
  - Improvements to map rotation when tracking user compass heading and when rotating the application orientation.
  - Annotations are now ordered in the third dimension according to relative screen position, including during map rotation.
  - Improved the map view delegate protocol to indicate direct user actions that change the map.
  - Reduced the amount of code necessary at map view initialization in order to behave more like MapKit.
  - Added an option to disable compass heading calibration display.
  - Map view delegate can now be set graphically in a XIB.
  - Added the ability to interact with the user location annotation.
  - Stability improvements when applications lose and regain location services permissions.
  - Improved ability to debug UTFGrid interactivity in Xcode.

### 0.3.0
#### July 5, 2012

  - First release of the prepackaged binary. 
  - Added support for MapBox markers. 
  - Improved the performance of vector paths and shapes when panning and zooming. 
  - Enhanced the performance and redrawing of multiple stacked tile layers. 
  - Other refactorings and improvements. 

### 0.2.0
#### June 8, 2012

  - Added user location services. 
  - Added configurable cache expiration handling. 
  - Enhancements for interactivity & composite sources. 
  - Xcode 4.3 compatibility. 
  - Minor bug fixes. 
  - Various upstream enhancements. 

### 0.1.0
#### April 16, 2012

  - Initial public release.