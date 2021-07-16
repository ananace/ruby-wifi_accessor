# frozen_string_literal: true

require_relative 'lib/wifi_accessor/version'

Gem::Specification.new do |spec|
  spec.name          = 'wifi_accessor'
  spec.version       = WifiAccessor::VERSION
  spec.authors       = ['Alexander \"Ace\" Olofsson']
  spec.email         = ['ace@haxalot.com']

  spec.summary       = 'Automatically access connected WiFi networks.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/ananace/ruby-wifi_accessor'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  spec.files         = Dir['{bin,lib}/**/*']
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.add_dependency 'capybara', '~> 3'
  spec.add_dependency 'poltergeist', '~> 1'

  spec.add_dependency 'ruby-dbus'
end
