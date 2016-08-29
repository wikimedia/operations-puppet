require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
root_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..'))

RSpec.configure do |c|
  c.module_path = [
          File.join(fixture_path, 'modules'),
          File.join(root_path, 'modules'),
      ].join(':')
  # Do not add c.manifest_dir which would boot manifests/site.pp
  c.template_dir = File.join(root_path, 'templates')
  c.environmentpath = File.join(Dir.pwd, 'spec')
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')

  # For --next-failure
  c.example_status_persistence_file_path = File.join(
      File.dirname(__FILE__), 'examples.txt')
end

# From Max Lincoln: https://gist.github.com/maxlinc/6382696
ENV['PUPPET_LOG'] = 'debug' if ENV['PUPPET_DEBUG']
if ENV['PUPPET_LOG']
    levels = %w{debug info notice warning err alert emerg crit}
    if !levels.include?(ENV['PUPPET_LOG'])
        raise "Unknown log level for PUPPET_LOG. Must be one of: #{levels}"
    end
    Puppet::Util::Log.level = :"#{ENV['PUPPET_LOG']}"
    Puppet::Util::Log.newdestination(:console)
end
