#!/bin/bash

HTMLTOP='<div id="header">'
HTMLEND='<div class="main-navigation navigation-bottom">'
YAML="\
---
title: iOS SDK `git tag | sort -r | sed -n '1p'`
layout: api
permalink: /api
categories: api
navigation:"
CONTENT="\
<p>Welcome to the iOS SDK API documentation. Here you can find details on the classes, protocols, and other parts of the SDK. You might also be interested in the <a href='/mapbox-ios-sdk/Docs/publish/docset.atom'>Atom feed</a>, which allows <a href='https://developer.apple.com/library/ios/#recipes/xcode_help-documentation_preferences/SettingDocPreferencesHelp.html'>direct embedding</a> of the documentation into Xcode.</p>
<p><img src='https://farm9.staticflickr.com/8532/8596722686_3edf70b878_z.jpg'/></p>
"

scrape() {
  FR=`grep -n "$HTMLTOP" $1 | grep -o [0-9]*`
  TO=`grep -n "$HTMLEND" $1 | grep -o [0-9]*`
  LINES=`echo "$TO - $FR" | bc`
  echo "$(tail -n +$FR $1 | head -n $LINES)"
}

YAML="$YAML\n  Classes:"
for file in `find /tmp/docset -wholename "*Classes/*.html" | sort`; do
  YAML="$YAML\n  - $(basename $file .html)-class"
  CONTENT="$CONTENT\n$(scrape $file)"
done

YAML="$YAML\n  Protocols:"
for file in `find /tmp/docset -wholename "*Protocols/*.html" | sort`; do
  YAML="$YAML\n  - $(basename $file .html)-protocol"
  CONTENT="$CONTENT\n$(scrape $file)"
done

echo -e "$YAML"
echo "---"
echo -e "$CONTENT" | \
  # Simplify CSS.
  sed 's,class="title ,class=",' | \
  sed 's,class="section ,class=",' | \
  # Add an id to <h1>'s so they can be looked up by anchor links.
  sed '/Class Reference/s,<h1 class="title-header">\([^<]*\)</h1>,<h1 class="title-header" id="\1-class">\1</h1>,' | \
  sed '/Protocol Reference/s,<h1 class="title-header">\([^<]*\)</h1>,<h1 class="title-header" id="\1-protocol">\1</h1>,' | \
  # Replace links to class/protocol pages with anchor links. Avoids http:// urls.
  sed 's,<a href="[^#\"]*Classes[^\"]*">\([^<]*\)</a>,<a href="#\1-class">\1</a>,g' | \
  sed 's,<a href="[^#\"]*Protocols[^\"]*">\([^<]*\)</a>,<a href="#\1-protocol">\1</a>,g' | \
  # Consider any pages left to also be protocols.
  sed 's,<a href="[^#\"]*\.html">\([^<]*\)</a>,<a href="#\1-protocol">\1</a>,g' | \
  # Simplify class/protocol titles.
  sed 's, Class Reference,,g' | \
  sed 's, Protocol Reference,,g' | \
  # Link header files to GitHub.
  sed 's,>\(.*\.h\)<,><a href="https://github.com/mapbox/mapbox-ios-sdk/blob/release/MapView/Map/\1">\1</a><,'
