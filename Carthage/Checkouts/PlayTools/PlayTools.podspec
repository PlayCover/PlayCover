#
# Be sure to run `pod lib lint GoChannel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'PlayTools'
    s.version          = '1.1.1'
    s.summary          = 'PlayTools from PlayCover'
    s.swift_versions   = '5'
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
    s.description      = <<-DESC
  TODO: Add long description of the pod here.
                         DESC
  
    s.homepage         = 'https://playcover.github.io/'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'AGPLv3', :file => 'LICENSE' }
    s.author           = { 'lucas lee' => 'lixin9311@gmail.com' }
    s.source           = { :git => 'https://github.com/PlayCover/PlayTools.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
    s.platforms = { :ios => "14.0" }
    s.source_files = 'PlayTools/**/*'
  
    # s.resource_bundles = {
    #   'GoChannel' => ['GoChannel/Assets/*.png']
    # }
    s.ios.framework  = 'UIKit', 'IOKit'
    s.exclude_files = "PlayTools/Info.plist"
    s.public_header_files = 'PlayTools/PlayTools.h.h'
    s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
    s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
    # s.frameworks = 'Cocoa'
    # s.dependency 'AFNetworking', '~> 2.3'
end