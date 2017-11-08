
Pod::Spec.new do |s|
  s.name             = 'AKDataSync'
  s.version          = '0.0.17'
  s.summary          = 'AKDataSync - Automated CoreData synchronization with iCloud'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
Description should be longer than summary.
more longer
much more longer
longer...
DESC

  s.homepage     = "https://github.com/Anobisoft/AKDataSync"
# s.screenshots  = "www.example.com/screenshots_1.gif"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Stanislav Pletnev" => "anobisoft@gmail.com" }
  s.social_media_url   = "https://twitter.com/Anobisoft"
  s.platform     = :ios, "10.0"
#  When using multiple platforms
# s.ios.deployment_target = "9.3"
# s.osx.deployment_target = "10.7"
# s.watchos.deployment_target = "2.0"
# s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/Anobisoft/AKDataSync.git", :tag => "v#{s.version}" }
  s.source_files  = "AKDataSync/Classes/*.{h,m}", "AKDataSync/Classes/**/*.{h,m}"
  s.public_header_files = "AKDataSync/Classes/*.h", "AKDataSync/Classes/Public/*.h"
  s.exclude_files = "AKDataSync/Classes/Deprecated/*"
# s.resource  = "icon.png"
  s.resources = "AKDataSync/Resources/*.plist"
# s.preserve_paths = "FilesToSave", "MoreFilesToSave"
  s.frameworks  = "Foundation", "CoreData", "CloudKit", "WatchConnectivity"
# s.library   = "iconv"
# s.libraries = "iconv", "xml2"
  s.requires_arc = true

# s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency "AnobiKit", '~> 0.1.18'

end
