#
# Be sure to run `pod lib lint ImageGradient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ImageGradient'
  s.version          = '0.1.0'
  s.summary          = 'An image wich is displayed as gradient.'

  s.homepage         = 'https://github.com/AlexBorodulin1989/ImageGradient'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Aleksandr Borodulin' => 'aleksanderborodoolin@mail.ru' }
  s.source           = { :git => 'https://github.com/AlexBorodulin1989/ImageGradient.git', :tag => s.version }
  s.swift_version    = '4.0'

  s.ios.deployment_target = '12.0'

  s.source_files = 'ImageGradient/Classes/**/*.{swift,metal}'
end
