#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint file_saver.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'file_saver'
  s.version          = '0.3.1'
  s.summary          = 'A Flutter plugin for saving files across all platforms.'
  s.description      = <<-DESC
A Flutter plugin for saving files across all platforms.
                       DESC
  s.homepage         = 'https://github.com/incrediblezayed/file_saver'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hassan Ansari' => 'contact@hassanansari.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'file_saver/Sources/file_saver/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
