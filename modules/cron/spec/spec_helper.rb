require 'rspec-puppet'

fixture_path = File.expand_path( File.join( __FILE__, '..', 'fixtures' ))

RSpec.configure do |spec|
  spec.module_path  = File.join( fixture_path, 'modules' )
  spec.manifest_dir = File.join( fixture_path, 'manifests' )
end

