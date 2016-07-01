require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

base_path = File.expand_path(File.dirname(File.dirname(__FILE__)))
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

Dir.glob('modules/*/lib').each do |module_lib|
    $LOAD_PATH.unshift module_lib
end

RSpec.configure do |c|
    c.example_status_persistence_file_path = '.rspec_status'
    c.run_all_when_everything_filtered = true

    c.manifest_dir = File.join(base_path, 'manifests')
    c.module_path = File.join(base_path, 'modules')
    c.template_dir = File.join(base_path, 'templates')

    # Fixtures
    c.manifest = File.join(fixture_path, 'site.pp')
    c.hiera_config = File.join(fixture_path, 'hiera.yaml')
end
