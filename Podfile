# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

use_frameworks!

def all_pods
  # Pods for Clew
  pod 'InAppSettingsKit'
  pod 'VectorMath', '~> 0.3'
  pod 'Firebase/Core'
  pod 'Firebase/Storage'
  pod 'Firebase/Database'
  pod 'SRCountdownTimer'
  pod 'PRTween', '~> 0.1'
  pod 'Firebase/Analytics'
  pod 'OpenCV'
  pod 'eigen'
  pod 'LASwift'
end

target 'Clew' do
    all_pods
end

target 'Clew Dev' do
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
