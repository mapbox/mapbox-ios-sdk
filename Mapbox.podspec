Pod::Spec.new do |m|

  m.name    = 'Mapbox'
  m.version = '1.2.0'

  m.summary     = 'Open source alternative to MapKit.'
  m.description = 'Open source alternative to MapKit supporting custom tile sources, offline use, and complete cache control.'
  m.homepage    = 'http://mapbox.com/mobile'
  m.license     = 'BSD'
  m.author      = { 'Mapbox' => 'mobile@mapbox.com' }
  m.screenshot  = 'https://raw.github.com/mapbox/mapbox-ios-sdk/packaging/screenshot.png'

  m.source = { :git => 'https://github.com/mapbox/mapbox-ios-sdk.git', :branch => 'develop' }

  m.platform              = :ios
  m.ios.deployment_target = '5.0'

  m.source_files = 'Proj4/*.h', 'MapView/Map/*.{h,c,m}'

  m.requires_arc = true

  m.prefix_header_file = 'MapView/MapView_Prefix.pch'

  m.resource_bundle = { 'Mapbox' => 'MapView/Map/Resources/*' }

  m.documentation_url = 'https://www.mapbox.com/mapbox-ios-sdk'

  m.frameworks = 'CoreGraphics', 'CoreLocation', 'Foundation', 'QuartzCore', 'UIKit'

  m.libraries = 'Proj4', 'sqlite3', 'z'

  m.xcconfig = { 'OTHER_LDFLAGS' => '-ObjC', 'LIBRARY_SEARCH_PATHS' => '"${PODS_ROOT}/Mapbox/Proj4"' }

  m.preserve_paths = 'MapView/MapView.xcodeproj', 'MapView/Map/Resources'

  m.vendored_libraries = 'Proj4/libProj4.a'

  m.dependency 'FMDB', '~> 2.2'
  m.dependency 'GRMustache', '6.8.3'
  m.dependency 'SMCalloutView', '2.0'

end
