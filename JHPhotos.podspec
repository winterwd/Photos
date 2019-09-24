#
# Be sure to run `pod lib lint JHPhotos.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JHPhotos'
  s.version          = '0.4.0'
  s.summary          = 'JHPhotos as Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://www.jianshu.com/u/06f42a993882'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'winter' => 'winter.wei@hey900.com' }
  s.source           = { :git => 'https://git.thy360.com/ios-compose/jh_photos.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'JHPhotos/Classes/**/*.swift'
  
  s.resource_bundles = {
    'JHPhotos' => ['JHPhotos/Assets/*.*']
  }

  s.frameworks = 'UIKit', 'Photos'
  s.dependency 'Kingfisher', '~> 4.0'

  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
end
