class puppetmaster::passenger {

	if ( $puppet_passenger_bind_address == "" ) {
		$puppet_passenger_bind_address = '*'
	}
	if ( $puppet_passenger_verify_client == "" ) {
		$puppet_passenger_verify_client = 'optional'
	}
	# Another variable available: $puppet_passenger_allow_from, which will
	# add an Allow from statement (and Order Allow,Deny), limiting access
	# to the passenger service.

	package { [ "puppetmaster", "puppetmaster-common", "puppetmaster-passenger", "vim-puppet", "puppet-el", "libapache2-mod-passenger", "libactiverecord-ruby1.8", "libactivesupport-ruby1.8", "libldap-ruby1.8" ]:
		ensure => latest;
	}

	file {
		"/etc/apache2/sites-available/puppetmaster":
			owner => root,
			group => root,
			mode => 0644,
			content => template('puppet/puppetmaster.erb'),
			require => Package["puppetmaster-passenger"];
		"/usr/local/bin/position-of-the-moon":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/puppet/position-of-the-moon";
	}

	if $puppet_environment_type == "labs" {
		# Use a specific revision for the checkout, to ensure we are using
		# a known and approved version of this script.
		file {
			"/usr/local/sbin/puppetsigner.py":
				ensure => link,
				target => "/usr/local/lib/instance-management/puppetsigner.py";
			"/etc/apache2/ports.conf":
				owner => root,
				group => root,
				mode  => 0644,
				source => "puppet:///files/puppet/ports.conf";
		}
		cron {
			"puppet_certificate_signer":
				command => "/usr/local/sbin/puppetsigner.py --scriptuser > /dev/null 2>&1",
				require => File["/usr/local/sbin/puppetsigner.py"],
				user    => root;
		}

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
