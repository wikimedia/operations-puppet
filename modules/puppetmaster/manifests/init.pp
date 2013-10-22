# Class: puppetmaster
#
# This class installs a Puppetmaster
#
# Parameters:
#	- $bind_address:
#		The IP address Apache will bind to
#	- $verify_client:
#		Whether apache mod_ssl will verify the client (SSLVerifyClient option)
#	- $allow_from:
#		Adds an Allow from statement (order Allow,Deny), limiting access
#		to the passenger service.
#	- $deny_from:
#		Adds a Deny from statement (order Allow,Deny), limiting access
#		to the passenger service.
#	- $config:
#		Hash containing all config settings for the [master] section of
#		puppet.conf (ini-style)
class puppetmaster(
            $server_name="puppet",
            $bind_address="*",
            $verify_client="optional",
            $allow_from=[],
            $deny_from=[],
            $config={})
    {
	system::role { "puppetmaster": description => "Puppetmaster" }

	$gitdir = "/var/lib/git"
	$volatiledir = "/var/lib/puppet/volatile"

	# Require /etc/puppet.conf to be in place, so the postinst scripts do the right things.
	require puppetmaster::config

	package { [
        "puppetmaster",
        "puppetmaster-common",
        "vim-puppet",
        "puppet-el",
        "rails",
        "libmysql-ruby",
        "ruby-json"
        ]:
		ensure => latest;
	}

    include backup::host
    backup::set { 'var-lib-puppet-ssl': }

	class { "puppetmaster::passenger":
		bind_address => $bind_address,
		verify_client => $verify_client,
		allow_from => $allow_from
	}

	class { "puppetmaster::ssl":
		server_name => $server_name,
		ca => $config['ca']
	}

	include puppetmaster::scripts
	include puppetmaster::geoip
	include puppetmaster::gitclone
	include puppetmaster::gitpuppet

	if $is_labs_puppet_master {
		include puppetmaster::labs
	}
}
