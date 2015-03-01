Pod::Spec.new do |s|
  s.name         = "AsakusaSatelliteSwiftClient"
  s.version      = "0.0.1"
  s.summary      = "A short description of AsakusaSatelliteSwiftClient."
  s.description  = <<-DESC
                   A longer description of AsakusaSatelliteSwiftClient in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC
  s.homepage     = "https://github.com/codefirst/AsakusaSatelliteSwiftClient"
  s.license      = "MIT (example)"
  s.author             = { "banjun" => "banjun@gmail.com" }
  s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.7"
  s.source       = { :git => "https://github.com/codefirst/AsakusaSatelliteSwiftClient.git", :tag => "0.0.1" }
  s.source_files  = "Classes", "Classes/**/*.{h,m,swift}"
  s.requires_arc = true
  s.dependency "Alamofire", "~> 1.1"
end
