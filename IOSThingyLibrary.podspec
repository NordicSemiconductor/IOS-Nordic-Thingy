Pod::Spec.new do |s|
  s.name             = 'IOSThingyLibrary'
  s.version          = '1.5.3'
  s.summary          = 'A Swift 5 SDK implementation for the Nordic Thingy:52 produced by Nordic Semiconductor'
  s.description      = <<-DESC
This is a mobile SDK for the Thingy:52 devices developed by Nordic Semiconductor. Thingy:52
is a development board with a vast amount of sensors, an input button and an RGB LED, fully
customizable thanks to its Bluetooth LE API that requires no firmware programming knowledge.
This SDK takes it a step further by allowing developers create their own Thingy:52 compatible
applications with ease.
			DESC

  s.homepage         = 'https://www.nordicsemi.com'
  # s.screenshots     = 'https://developer.nordicsemi.com/thingy/screenshots'
  s.license          = { :type => 'Nordic 5-Clause', :file => 'LICENSE' }
  s.author           = { 'Aleksander Nowakowski' => 'aleksander.nowakowski@nordicsemi.no',
                         'Dinesh Harjani' => 'dinesh.harjani@nordicsemi.no' }
  s.source           = { :git => 'https://github.com/NordicSemiconductor/IOS-Nordic-Thingy.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nordictweets'
  s.swift_versions = ['4.2', '5.0']

  s.ios.deployment_target = '12.0'

  s.source_files = 'IOSThingyLibrary/Classes/**/*'

  s.dependency 'iOSDFULibrary', '~> 4.13.0'
end
