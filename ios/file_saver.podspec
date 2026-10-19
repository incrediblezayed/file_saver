#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint file_saver.podspec` to validate before publishing.
#

# Whether to build saveToGallery and link Photos. Same rules as Package.swift:
# 1. FILE_SAVER_PHOTOS is set: "0" means off, anything else means on.
# 2. The app's ios/Runner/Info.plist has a photo library usage key: on.
#    It has neither key: off.
# 3. Info.plist can't be found or read: on.
# See "Gallery support on iOS" in the README.
gallery_enabled = begin
  value = ENV['FILE_SAVER_PHOTOS'].to_s
  if value.empty?
    plist = File.join(Pod::Config.instance.installation_root.to_s, 'Runner', 'Info.plist')
    !File.exist?(plist) || File.binread(plist).match?(/NSPhotoLibrary(Add)?UsageDescription/n)
  else
    value != '0'
  end
rescue StandardError
  true
end

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
  s.frameworks = 'Photos' if gallery_enabled
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) FILE_SAVER_PHOTOS' if gallery_enabled
  s.pod_target_xcconfig = xcconfig
  s.swift_version = '5.9'
end
