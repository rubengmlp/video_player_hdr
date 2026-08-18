#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint video_player_hdr.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'video_player_hdr'
  s.version          = '2.1.0'
  s.summary          = 'A fork of Flutter video_player with HDR support'
  s.description      = <<-DESC
A fork of Flutter video_player that adds HDR support.
                       DESC
  s.homepage         = 'https://github.com/rubengmlp/video_player_hdr'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Rubén Gómez López' => 'rubengmlp@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'video_player_hdr/Sources/video_player_hdr/**/*.swift'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.dependency 'Flutter'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end 