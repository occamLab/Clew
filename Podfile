# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

use_frameworks!

def all_pods
   pod 'ARCore/Geospatial', '~> 1.32.0'
   pod 'ARCore/CloudAnchors', '~> 1.32.0'
   pod 'FirebaseStorage'
   pod 'FirebaseAnalytics'
   pod 'FirebaseAuth'
# Firebase DB causes app store errors when combined with ARCore
#   pod 'FirebaseDatabase'
   pod 'LASwift'
   pod 'VectorMath'
   pod 'InAppSettingsKit'
   pod 'JGMethodSwizzler', '2.0.1'
end

target 'Clew-More' do
    all_pods
end

# manually set the swift version for SRCountdownTimer since it doesn't work with Swift 5.0
post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['SRCountdownTimer'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end
