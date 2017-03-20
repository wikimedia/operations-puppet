# Setup puppet to use the real modules / hieradata from production

require 'rspec-puppet'
require 'hiera'

root_path = File.expand_path(File.join(__FILE__, '..', '..', '..', '..' ))
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

# Our custom Hiera backends such as nuyaml
$LOAD_PATH << File.expand_path(File.join(root_path, 'modules/wmflib/lib'))


def prepare_hiera_config(root_path, fixture_path)
	# Production hiera configuration
    hiera_conf = File.read(
        File.join(root_path,
                  'modules/puppetmaster/files/production.hiera.yaml'))

	# Rewrite paths
    hiera_conf.gsub!('/etc/puppet/hieradata',
                     File.join(root_path, 'hieradata'))
    hiera_conf.gsub!('/etc/puppet/private/hieradata',
                     File.join(root_path, 'private/hieradata'))
    hiera_conf.prepend("# *** Auto-generated ***\n")

    File.write(File.join(fixture_path, 'hiera.yaml'), hiera_conf)
end

RSpec.configure do |c|
	# Use real manifests/templates...
	c.module_path = [
		File.join(root_path, 'modules'),
	#	File.join(root_path, 'private', 'modules'),
	].join(':')
	c.template_dir = File.join(root_path, 'templates')
	#c.environmentpath = File.join(Dir.pwd, 'spec')

    # Dummy site.pp
	c.manifest_dir = File.join(fixture_path, 'manifests')

	# For hiera use a rewritten configuration file
	prepare_hiera_config(root_path, fixture_path)
	c.hiera_config = File.join(fixture_path, 'hiera.yaml')
end
