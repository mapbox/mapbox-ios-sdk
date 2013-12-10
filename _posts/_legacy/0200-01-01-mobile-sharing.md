---
date: 0200-02-08
category: guide
layout: guide
title: Sharing maps
---
You may want to think about sharing your maps, either in-person with a visual presentation, taking a snapshot and sharing them digitally, or sharing the data with other apps on the system.

## Sharing map data

Sharing map data is easy with a format like [MBTiles](http://mbtiles.org), which allows for millions of [map tiles]({{site.baseurl}}/mobile/docs/tiles) to be transferred as a unit. You can treat `.mbtiles` files as documents in your apps, or change the file extension and customize them a bit more.

Sharing point, line, and other geometry data is best done with a format such as [GeoJSON](http://geojson.org/) or [KML and KMZ](https://developers.google.com/kml/). These formats allow for storage of georeferenced points, which can then be parsed and displayed in a manner most appropriate for the platform. You may want to consider [various methods of displaying these types of data]({{site.baseurl}}/mobile/docs/data) to determine the best one for your use case.

 * [Simple KML](https://github.com/mapbox/Simple-KML) - our open source library for KML/KMZ parsing on iOS

## Presenting maps

With apps like [Mapbox for iPad]({{site.baseurl}}/ipad), you can easily mirror the current map view to an external display using the open source [Fingertips](http://github.com/developmentseed/fingertips) library. This library helps show the audience where the presenter's multitouch gestures are affecting the app.

 * [Fingertips](http://github.com/developmentseed/fingertips) - our open source library for mirroring presentations and touches on iOS

![](http://farm4.staticflickr.com/3460/5734313608_cb3c1a2c6a.jpg)
