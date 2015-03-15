Pod::Spec.new do |s|
  s.name         = "AsakusaSatellite"
  s.version      = "0.0.1"
  s.summary      = "AsakusaSatellite API Client for Swift"
  s.description  = <<-DESC
                   AsakusaSatellite is a realtime chat application for developers.
                   DESC
  s.homepage     = "https://github.com/codefirst/AsakusaSatelliteSwiftClient"
  s.license      = "MIT"
  s.author       = { "banjun" => "banjun@gmail.com" }
  s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.10"
  s.source       = { :git => "https://github.com/codefirst/AsakusaSatelliteSwiftClient.git", :tag => "0.0.1" }
  s.source_files  = "Classes/*.swift"
  s.requires_arc = true
  s.dependency "Alamofire", "~> 1.1"
  s.dependency "SwiftyJSON", "~> 2.1"
  s.dependency "Socket.IO-Client-Swift", "~> 1.1"

  s.subspec 'iOS' do |ss|
    ss.ios.deployment_target = '8.0'
    ss.ios.source_files = 'Classes/iOS/*.swift'
    ss.osx.source_files = ''
  end
end
