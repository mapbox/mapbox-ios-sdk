#!/bin/bash
git push --tags
pod repo push hitta Mapbox-iOS-SDK-Hitta.podspec --allow-warnings $1
