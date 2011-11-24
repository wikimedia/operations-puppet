import "generic-definitions.pp"

class puppetmaster($bind_address="*", $verify_client="optional", $allow_from=undef) {
	system_role { "puppetmaster": description => "Puppetmaster" }

<<<<<<< HEAD   (ddb719 dupload configuration)
	# Require /etc/puppet.conf to be in place, so the postinst scripts do the right things.
	require "base::puppet"

	package { [ "puppetmaster", "puppetmaster-common", "vim-puppet", "puppet-el", "rails" ]:
=======
	package { [ "puppetmaster", "puppetmaster-common", "vim-puppet", "puppet-el" ]:
>>>>>>> BRANCH (341781 Move Package[git-core] into a generic-definitions class)
		ensure => latest;
	}
<<<<<<< HEAD   (ddb719 dupload configuration)
	
	$ssldir = "/var/lib/puppet/server/ssl"
	# Move the puppetmaster's SSL files to a separate directory from the client's
	file {
		[ "/var/lib/puppet/server", $ssldir ]:
			require => Package["puppetmaster"],
			ensure => directory,
			owner => puppet,
			group => root,
			mode => 0771;
		[ "$ssldir/ca", "$ssldir/certificate_requests", "$ssldir/certs", "$ssldir/private", "$ssldir/private_keys", "$ssldir/public_keys" ]:
			ensure => directory;
	}
	
	exec { "generate hostcert":
		require => File["$ssldir/certs"],
		command => "/usr/bin/puppet cert generate ${fqdn}",
		creates => "$ssldir/certs/${fqdn}.pem"
	}
	
	# Link the server SSL host cert to the client side cert
	file {
		"${ssldir}/certs/${fqdn}.pem":
			ensure => "/var/lib/puppet/ssl/certs/${fqdn}.pem";
		"${ssldir}/private_keys/${fqdn}.pem":
			ensure => "/var/lib/puppet/ssl/private_keys/${fqdn}.pem";
	}
	
	# TODO fileserver.conf
=======

	class passenger {
		$puppet_passenger_bind_address = $bind_address
		$puppet_passenger_verify_client = $verify_client
		# Another variable available: $puppet_passenger_allow_from, which will
		# add an Allow from statement (and Order Allow,Deny), limiting access
		# to the passenger service.
		$puppet_passenger_allow_from = $allow_from
>>>>>>> BRANCH (341781 Move Package[git-core] into a generic-definitions class)

<<<<<<< HEAD   (ddb719 dupload configuration)
	class passenger {
		require puppetmaster
		
		$puppet_passenger_bind_address = $bind_address
		$puppet_passenger_verify_client = $verify_client
		# Another variable available: $puppet_passenger_allow_from, which will
		# add an Allow from statement (and Order Allow,Deny), limiting access
		# to the passenger service.
		$puppet_passenger_allow_from = $allow_from

=======
>>>>>>> BRANCH (341781 Move Package[git-core] into a generic-definitions class)
		package { [ "puppetmaster-passenger", "libapache2-mod-passenger" ]:
			ensure => latest;
		}

		file {
			"/etc/apache2/sites-available/puppetmaster":
				owner => root,
				group => root,
				mode => 0444,
				content => template('puppet/puppetmaster.erb'),
				require => Package["puppetmaster-passenger"];
		}

		apache_module { "passenger":
			name => "passenger",
			require => Package["libapache2-mod-passenger"];
		}
		apache_site { "puppetmaster":
			name => "puppetmaster",
			require => Apache_module["passenger"];
		}

		# Since we are running puppet via passenger, we need to ensure
		# the puppetmaster service is stopped, since they use the same port
		# and will conflict when both started.
		service { "puppetmaster":
			enable => false,
			ensure => stopped;
		}
	}
	
	class labs {
		include generic::packages::git-core
		
		package { "libldap-ruby1.8": ensure => latest; }

		# Use a specific revision for the checkout, to ensure we are using
		# a known and approved version of this script.
		file {
			"/usr/local/sbin/puppetsigner.py":
				ensure => link,
				target => "/usr/local/lib/instance-management/puppetsigner.py";
			"/etc/apache2/ports.conf":
				owner => root,
				group => root,
				mode  => 0444,
				source => "puppet:///files/puppet/ports.conf";
		}

		cron {
			"puppet_certificate_signer":
				command => "/usr/local/sbin/puppetsigner.py --scriptuser > /dev/null 2>&1",
				require => File["/usr/local/sbin/puppetsigner.py"],
				user    => root;
			"update_private_puppet_repos":
				command => "(cd /root/testrepo/private && /usr/bin/git pull) > /dev/null 2>&1",
				environment => "GIT_SSH=/root/testrepo/ssh",
				require => Package["git-core"],
				user    => root;
			"update_public_puppet_repos":
				command => "(cd /root/testrepo/puppet && /usr/bin/git pull) > /dev/null 2>&1",
				environment => "GIT_SSH=/root/testrepo/ssh",
				require => Package["git-core"],
				user    => root;
		}
	}
	
	class scripts {
		file {
			"/usr/local/bin/position-of-the-moon":
				owner => root,
				group => root,
				mode => 0555,
				source => "puppet:///files/puppet/position-of-the-moon";
			"/usr/local/bin/uuid-generator":
				owner => root,
				group => root,
				mode => 0555,
				source => "puppet:///files/puppet/uuid-generator";
		}

		cron {
			updategeoipdb:
				environment => "http_proxy=http://brewster.wikimedia.org:8080",
				command => "wget -qO - http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /etc/puppet/files/misc/GeoIP.dat.new && mv /etc/puppet/files/misc/GeoIP.dat.new /etc/puppet/files/misc/GeoIP.dat; wget -qO - http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /etc/puppet/files/misc/GeoIPcity.dat.new && mv /etc/puppet/files/misc/GeoIPcity.dat.new /etc/puppet/files/misc/GeoIPcity.dat",
				user => root,
				hour => 3,
				minute => 26,
				ensure => present;
		}
	}
	
	include passenger, scripts

	if $is_labs_puppet_master {
		include labs
	}

}
