Pod::Spec.new do |s|
  s.name         = "AsakusaSatellite"
  s.version      = "0.3.2"
  s.summary      = "AsakusaSatellite API Client for Swift"
  s.description  = <<-DESC
                   AsakusaSatellite is a realtime chat application for developers.
                   DESC
  s.homepage     = "https://github.com/codefirst/AsakusaSatelliteSwiftClient"
  s.license      = "MIT"
  s.author       = { "banjun" => "banjun@gmail.com" }
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.source       = { :git => "https://github.com/codefirst/AsakusaSatelliteSwiftClient.git", :tag => s.version.to_s }
  s.source_files = 'Classes/*.swift'
  s.ios.source_files = 'Classes/ios/*.swift'
  s.osx.source_files = ''
  s.requires_arc = true
  s.dependency "Alamofire", "~> 2.0"
  s.dependency "SwiftyJSON", "~> 2.2"
  s.dependency "Socket.IO-Client-Swift", "~> 3.1"
  s.dependency "UTIKit", "~> 1.2"
end
