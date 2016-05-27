require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.environmentpath = File.join(Dir.pwd, 'spec')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')

  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end
end
