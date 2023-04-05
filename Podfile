# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

use_frameworks!

def all_pods
   pod 'ARCore/Geospatial', '~> 1.36.0'
   pod 'ARCore/CloudAnchors', '~> 1.36.0'
   pod 'SwiftProtobuf'
   pod 'FirebaseStorage'
   pod 'FirebaseAnalytics'
   pod 'FirebaseAuth'
   pod 'SWCompression'
# Firebase DB causes app store errors when combined with ARCore
#   pod 'GeoFire'
   pod 'FirebaseFirestore'
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
    installer.generated_projects.each do |project|
          project.targets.each do |target|
              target.build_configurations.each do |config|
                  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
               end
          end
   end
end
