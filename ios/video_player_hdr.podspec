#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint video_player_hdr.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'video_player_hdr'
  s.version          = '0.0.1'
  s.summary          = 'A fork of Flutter video_player with HDR support'
  s.description      = <<-DESC
A fork of Flutter video_player that adds HDR support.
                       DESC
  s.homepage         = 'https://github.com/rubengomez/video_player_hdr'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Rubén Gómez López' => 'rubengmlp@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '10.0'
  s.dependency 'Flutter'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end 