import "generic-definitions.pp"

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
class puppetmaster($server_name="puppet", $bind_address="*", $verify_client="optional", $allow_from=[], $deny_from=[], $config={}) {
	system_role { "puppetmaster": description => "Puppetmaster" }

	# Require /etc/puppet.conf to be in place, so the postinst scripts do the right things.
	require config

	package { [ "puppetmaster", "puppetmaster-common", "vim-puppet", "puppet-el", "rails" ]:
		ensure => latest;
	}
	
	$ssldir = "/var/lib/puppet/server/ssl"
	# Move the puppetmaster's SSL files to a separate directory from the client's
	file {
		[ "/var/lib/puppet/server", $ssldir ]:
			require => Package["puppetmaster"],
			ensure => directory,
			owner => puppet,
			group => root,
			mode => 0771;
		[ "$ssldir/ca", "$ssldir/certificate_requests", "$ssldir/certs", "$ssldir/private", "$ssldir/private_keys", "$ssldir/public_keys", "$ssldir/crl" ]:
			ensure => directory;
	}
	
	exec {
		"generate hostcert":
			require => File["$ssldir/certs"],
			command => "/usr/bin/puppet cert generate ${server_name}",
			creates => "$ssldir/certs/${server_name}.pem";
		"setup crl dir":
			require => File["$ssldir/crl"],
			path => "/usr/sbin:/usr/bin:/sbin:/bin",
			command => "ln -s ${ssldir}/ca/ca_crl.pem ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).0",
			onlyif => "test ! -L ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).0"
	}

	# Class: puppetmaster::config
	#
	# This class handles the master part of /etc/puppet.conf. Do not include directly.
	class config {
		include base::puppet
		
		file {
			"/etc/puppet/puppet.conf.d/20-master.conf":
				require => File["/etc/puppet/puppet.conf.d"],
				owner => root,
				group => root,
				mode => 0444,
				content => template("puppet/puppet.conf.d/20-master.conf.erb"),
				notify => Exec["compile puppet.conf"];
			"/etc/puppet/fileserver.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => template("puppet/fileserver.conf.erb")
		}
	}

	# Class: puppetmaster::passenger
	#
	# This class handles the Apache Passenger specific parts of a Puppetmaster
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
	class passenger($bind_address="*", $verify_client="optional", $allow_from=[], $deny_from=[]) {
		require puppetmaster

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

	# Class: puppetmaster::labs
	#
	# This class handles the Wikimedia Labs specific buts of a Puppetmaster
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
	
	# Class: puppetmaster::scripts
	#
	# This class installs some puppetmaster server side scripts required for the manifests
	class scripts {
		File { mode => 0555 }
		file {
			"/usr/local/bin/position-of-the-moon":
				source => "puppet:///files/puppet/position-of-the-moon";
			"/usr/local/bin/uuid-generator":
				source => "puppet:///files/puppet/uuid-generator";
			"/usr/local/sbin/puppetstoredconfigclean.rb":
				source => "puppet:///files/puppet/puppetstoredconfigclean.rb";
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

		# Purge decommissioned hosts from the stored configs db		
		schedule { "nightly":
			range => "2 - 6",
			period => daily,
		}
		
		exec { "purge decommissioned hosts":
			path => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin/:/sbin",
			command => "for srv in $(cut -d'\"' -f 2 -s /etc/puppet/manifests/decommissioning.pp); do puppetstoredconfigclean.rb $srv.wikimedia.org $srv.esams.wikimedia.org $srv.pmtpa.wmnet $srv.eqiad.wmnet; done",
			schedule => nightly
		}
	}
	
	# Class: puppetmaster::dashboard
	#
	# This class installs a Puppet Dashboard interface for managing all Puppet clients
	#
	# Parameters:
	#	- $dashboard_environment:
	#		The RAILS environment dashboard should run in (production, development, test)
	#	- $db_host
	#		Hostname of the MySQL database server to use
	class dashboard($dashboard_environment="production", $db_host="localhost") {
		require puppetmaster::passenger, passwords::puppetmaster::dashboard

		system_role { "puppetmaster::dashboard": description => "Puppet Dashboard interface" }

		$db_pass = $passwords::puppetmaster::dashboard::db_pass

		package { "puppet-dashboard": ensure => latest }

		File { mode => 0444 }
		file {
			"/etc/apache2/sites-available/dashboard":
				content => template("puppet/dashboard/dashboard.erb");
			"/etc/puppet-dashboard/database.yml":
				require => Package["puppet-dashboard"],
				content => template("puppet/dashboard/database.yml.erb");
			"/etc/puppet-dashboard/settings.yml":
				require => Package["puppet-dashboard"],
				content => template("puppet/dashboard/settings.yml.erb");
			"/etc/default/puppet-dashboard":
				content => template("puppet/dashboard/puppet-dashboard.default.erb");
			"/etc/default/puppet-dashboard-workers":
				content => template("puppet/dashboard/puppet-dashboard-workers.default.erb");
		}
		
		apache_site { "dashboard":
			name => "dashboard",
			require => Exec["migrate database"]
		}

		Exec {
			path => "/usr/bin:/bin",
			cwd => "/usr/share/puppet-dashboard",
			subscribe => Package["puppet-dashboard"],
			refreshonly => true
		}
		exec {
			"create database":
				require => File["/etc/puppet-dashboard/database.yml"],
				command => "rake RAILS_ENV=${dashboard_environment} db:create";
			"migrate database":
				command => "rake RAILS_ENV=${dashboard_environment} db:migrate";
		}
		Exec["create database"] -> Exec["migrate database"] -> Service["puppet-dashboard-workers"]

		service { "puppet-dashboard-workers": ensure => running }
		
		# Temporary fix for dashboard under Lucid
		# http://projects.puppetlabs.com/issues/8800
		if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") == 0 {
			file { "/etc/puppet-dashboard/dashboard-fix-requirements-lucid.patch":
				require => Package["puppet-dashboard"],
				before => Exec["migrate database"],
				source => "puppet:///files/puppet/dashboard/dashboard-fix-requirements-lucid.patch"
			}
			
			exec { "fix gem-dependency.rb":
				command => "patch -p0 < /etc/puppet-dashboard/dashboard-fix-requirements-lucid.patch",
				cwd => "/usr/share/puppet-dashboard/vendor/rails/railties/lib/rails",
				require => File["/etc/puppet-dashboard/dashboard-fix-requirements-lucid.patch"],
				before => [Apache_site[dashboard], Service["puppet-dashboard-workers"]],
				subscribe => Package["puppet-dashboard"],
				refreshonly => true
			}
		}
	}
	
	class { "puppetmaster::passenger":
		bind_address => $bind_address,
		verify_client => $verify_client,
		allow_from => $allow_from
	}
	
	include scripts

	if $is_labs_puppet_master {
		include labs
	}

}
