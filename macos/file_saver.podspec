#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint file_saver.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'file_saver'
  s.version          = '0.3.1'
  s.summary          = 'Save files across Flutter platforms.'
  s.description      = <<-DESC
FileSaver saves files from bytes, paths, streams, and URLs across Flutter platforms.
                       DESC
  s.homepage         = 'https://github.com/incrediblezayed/file_saver'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hassan Ansari' => 'hassanansari222@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'file_saver/Sources/file_saver/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.9'
end
