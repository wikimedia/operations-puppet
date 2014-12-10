require 'rspec-puppet'

RSpec.configure do |c|
	#c.hiera_config =
	c.manifest_dir = 'manifests'
	c.module_path = 'private/modules:modules'
    c.template_dir = 'templates'

    c.default_facts = {
        :operatingsystem => 'Ubuntu',
        :interfaces => 'lo, eth0',
        :ipaddress => '10.64.0.0',  # will $site = 'eqiad'

        :lsbdistcodename => 'trusty',
        :lsbdistid => 'Ubuntu',
        :lsbdistrelease => '14.04',
    }
end
