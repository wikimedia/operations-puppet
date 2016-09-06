require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

root_path = File.expand_path(File.join(__FILE__, '..', '..', '..'))
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

def prepare_hiera_config(root_path, fixture_path)
    hiera_conf = File.read(
        File.join(root_path,
                  'modules/puppetmaster/files/production.hiera.yaml'))
    hiera_conf.gsub!('/etc/puppet/hieradata',
                     File.join(root_path, 'hieradata'))
    hiera_conf.gsub!('/etc/puppet/private/hieradata',
                     File.join(root_path, 'private/hieradata'))
    hiera_conf.prepend("# *** Auto-generated ***\n")
    File.write(File.join(fixture_path, 'generated_hiera.yaml'), hiera_conf)
end


RSpec.configure do |c|
  c.module_path = [
      File.join(root_path, 'modules'),
      File.join(root_path, 'private', 'modules'),
      ].join(':')
  c.manifest_dir = File.join(root_path, 'manifests')
  c.template_dir = File.join(root_path, 'templates')
  c.environmentpath = File.join(Dir.pwd, 'spec')

  prepare_hiera_config(root_path, fixture_path)

  c.hiera_config = File.join(fixture_path, 'generated_hiera.yaml')

  # For --next-failure
  c.example_status_persistence_file_path = File.join(
      File.dirname(__FILE__), 'examples.txt')

  c.before(:each) do
    # From Max Lincoln: https://gist.github.com/maxlinc/6382696
    ENV['PUPPET_LOG'] = 'debug' if ENV['PUPPET_DEBUG']
    if ENV['PUPPET_LOG']
        levels = %w(debug info notice warning err alert emerg crit)
        if !levels.include?(ENV['PUPPET_LOG'])
            raise "Unknown log level for PUPPET_LOG. Must be one of: #{levels}"
        end
        Puppet::Util::Log.level = :"#{ENV['PUPPET_LOG']}"
        Puppet::Util::Log.newdestination(:console)
    end
  end
end
