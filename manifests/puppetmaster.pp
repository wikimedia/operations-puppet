import "generic-definitions.pp"

class puppetmaster {
	system_role { "puppetmaster": description => "Puppetmaster" }

	package { [ "puppetmaster", "puppetmaster-common", "vim-puppet", "puppet-el" ]:
		ensure => latest;
	}

	class passenger {
		if ( $puppet_passenger_bind_address == "" ) {
			$puppet_passenger_bind_address = '*'
		}
		if ( $puppet_passenger_verify_client == "" ) {
			$puppet_passenger_verify_client = 'optional'
		}
		# Another variable available: $puppet_passenger_allow_from, which will
		# add an Allow from statement (and Order Allow,Deny), limiting access
		# to the passenger service.

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
