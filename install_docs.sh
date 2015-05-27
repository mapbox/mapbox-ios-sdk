#!/bin/sh

if [ -z `which appledoc` ]; then
    echo "Unable to find appledoc. Consider installing it from source or Homebrew."
    exit 1
fi

VERSION=$( git tag | sort -r | sed -n '1p' )
echo "Creating new docs for $VERSION..."
echo

appledoc \
    --output /tmp/`uuidgen` \
    --project-name "Mapbox iOS SDK $VERSION" \
    --project-company Mapbox \
    --create-docset \
    --company-id com.mapbox \
    --ignore build \
    --ignore FMDB \
    --ignore GRMustache \
    --ignore SMCalloutView \
    --ignore .c \
    --ignore .m \
    --ignore RMAttributionViewController.h \
    --ignore RMBingSource.h \
    --ignore RMCoordinateGridSource.h \
    --ignore RMDBMapSource.h \
    --ignore RMFoundation.h \
    --ignore RMFractalTileProjection.h \
    --ignore RMGenericMapSource.h \
    --ignore RMGlobalConstants.h \
    --ignore RMLoadingTileView.h \
    --ignore RMMapOverlayView.h \
    --ignore RMMapQuestOpenAerialSource.h \
    --ignore RMMapQuestOSMSource.h \
    --ignore RMMapScrollView.h \
    --ignore RMMapTiledLayerView.h \
    --ignore RMNotifications.h \
    --ignore RMOpenCycleMapSource.h \
    --ignore RMOpenSeaMapLayer.h \
    --ignore RMOpenSeaMapSource.h \
    --ignore RMPixel.h \
    --ignore RMProjection.h \
    --ignore RMTile.h \
    --ignore RMTileImage.h \
    --ignore RMTileSourcesContainer.h \
    --index-desc README.markdown \
    .