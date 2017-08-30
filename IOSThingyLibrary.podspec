Pod::Spec.new do |s|
  s.name             = 'IOSThingyLibrary'
  s.version          = '1.1.1'
  s.summary          = 'A Swift 3 SDK implementation for the Nordic:Thingy32 produced by Nordic Semiconductor'
  s.description      = <<-DESC
This is a mobile SDK for the Thingy:52 devices developed by Nordic Semiconductor, the Thingy
is a development board with a vast amount of sensors, an input button and a RGB LED, fully
customizable thanks to its Bluetooth API that requires no firmware programming knowledge.
This SDK takes it a step further by allowing developers create their own Thingy:52 compatible
applications with ease.
			DESC

  s.homepage         = 'https://www.nordicsemi.com'
  # s.screenshots     = 'https://developer.nordicsemi.com/thingy/screenshots'
  s.license          = { :type => 'Nordic 5-Clause', :file => 'LICENSE' }
  s.author           = { 'Mostafa Berg' => 'mostafa.berg@nordicsemi.no' , 'Aleksander Nowakowski' => 'aleksander.nowakowski@nordicsemi.no'}
  s.source           = { :git => 'https://github.com/NordicSemiconductor/IOS-Nordic-Thingy.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nordictweets'

  s.ios.deployment_target = '8.0'

  s.source_files = 'IOSThingyLibrary/Classes/**/*'

  s.dependency 'iOSDFULibrary', '~> 3.0'
end
