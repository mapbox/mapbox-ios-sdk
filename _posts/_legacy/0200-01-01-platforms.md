---
date: 0200-02-02
category: guide
layout: guide
title: Platforms
---
The core Mapbox technology will work on both iOS and Android, both with native apps and with mobile browsers. Our team has focused on iOS native development and cross-platform web technologies, and to date has only played with Android development apps, so these docs tend to focus on iOS and mobile browser technologies. But, we link to resources, where we can, for Android app developers using Mapbox and are hoping to grow our coverage of Android in the coming months.

If you have a specific question on mobile, or want us to list a mobile app that you are developing using Mapbox, just start a conversation on [our support site](http://support.mapbox.com).

## Choosing between native and web

Mapbox supports a wealth of code libraries for use on Apple's iOS. It is our mobile platform of choice and we have developed [production apps]({{site.baseurl}}/mobile/docs/apps), an [SDK]({{site.baseurl}}/mobile), and [sample code]({{site.baseurl}}/mobile/docs/examples).

However, web browser technologies such as [Modest Maps](http://modestmaps.com/), [Leaflet](http://leaflet.cloudmade.com/), [Wax](http://mapbox.com/wax/), and [Easey](http://mapbox.com/easey/) will work well on many mobile browsers. Most browsers are based on the open source [WebKit](http://www.webkit.org/) rendering engine, which has robust support for today's web technologies. Consider using web technologies when you want to deploy to multiple platforms, have more control over the release of code updates, or already have web expertise.

Currently, Google's Android family of mobile operating systems is best suited to native application development due to limitations in the browsing environment. You may wish to check out the [MBTiles open format implementations](https://github.com/mapbox/mbtiles-spec/wiki/Implementations) resource as a starting point.

In general, native development will provide better performance, particularly when it comes to more responsive multitouch interaction, as well as more robust [offline support]({{site.baseurl}}/mobile/docs/offline). Native development will also generally be better for [drawing data overlays]({{site.baseurl}}/mobile/docs/data) on-the-fly rather than including them in map tiles.
