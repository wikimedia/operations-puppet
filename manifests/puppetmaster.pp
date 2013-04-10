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

	$gitdir = "/var/lib/git"
	$volatiledir = "/var/lib/puppet/volatile"

	# Require /etc/puppet.conf to be in place, so the postinst scripts do the right things.
	require config

	package { [ "puppetmaster", "puppetmaster-common", "vim-puppet", "puppet-el", "rails", "libmysql-ruby", "ruby-json" ]:
		ensure => latest;
	}

	class ssl($server_name="puppet", $ca="false") {
		$ssldir = "/var/lib/puppet/server/ssl"

		# Move the puppetmaster's SSL files to a separate directory from the client's
		file {
			[ "/var/lib/puppet/server", $ssldir ]:
				before => Package["puppetmaster"],
				ensure => directory,
				owner => puppet,
				group => root,
				mode => 0771;
			[ "/var/lib/puppet", "$ssldir/ca", "$ssldir/certificate_requests", "$ssldir/certs", "$ssldir/private", "$ssldir/private_keys", "$ssldir/public_keys", "$ssldir/crl" ]:
				ensure => directory;
		}

		if $ca != "false" {
			exec { "generate hostcert":
				require => File["$ssldir/certs"],
				command => "/usr/bin/puppet cert generate ${server_name}",
				creates => "$ssldir/certs/${server_name}.pem";
			}
		}

		exec { "setup crl dir":
			require => File["$ssldir/crl"],
			path => "/usr/sbin:/usr/bin:/sbin:/bin",
			command => "ln -s ${ssldir}/ca/ca_crl.pem ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).0",
			onlyif => "test ! -L ${ssldir}/crl/$(openssl crl -in ${ssldir}/ca/ca_crl.pem -hash -noout).0"
		}
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
				content => template("puppet/fileserver.conf.erb");
		}
	}

	# Class: puppetmaster::gitclone
	#
	# This class handles the repositories from which the puppetmasters pull
	class gitclone {

		file {
			"$puppetmaster::gitdir":
				ensure => directory,
				owner => root,
				group =>root;
			"$puppetmaster::gitdir/operations":
				ensure => directory,
				owner => root,
				group => root;
			"$puppetmaster::gitdir/operations/puppet/.git/hooks/post-merge":
				require => Git::Clone["operations/puppet"],
				source => "puppet:///files/puppet/git/puppet/post-merge",
				mode => 0550;
			"$puppetmaster::gitdir/operations/puppet/.git/hooks/pre-commit":
				require => Git::Clone["operations/puppet"],
				source => "puppet:///files/puppet/git/puppet/pre-commit",
				mode => 0550;
			"$puppetmaster::gitdir/operations/software/.git/hooks/pre-commit":
				require => Git::Clone["operations/software"],
				source => "puppet:///files/puppet/git/puppet/pre-commit",
				mode => 0550;
			"$puppetmaster::volatiledir":
				mode => 0750,
				owner => root,
				group => puppet,
				ensure => directory;
			"$puppetmaster::volatiledir/misc":
				mode => 0750,
				owner => root,
				group => puppet,
				ensure => directory;
		}

		if ! $is_labs_puppet_master {
			file {
				"$puppetmaster::gitdir/operations/private":
					ensure => directory,
					owner => root,
					group => puppet,
					mode => 0750;

				"$puppetmaster::gitdir/operations/private/.git/hooks/post-merge":
					source => "puppet:///files/puppet/git/private/post-merge",
					mode => 0550;
			}
		}

		git::clone {
			"operations/puppet":
				require => File["$puppetmaster::gitdir/operations"],
				directory => "$puppetmaster::gitdir/operations/puppet",
				branch => "production",
				origin => "https://gerrit.wikimedia.org/r/p/operations/puppet";
			"operations/software":
				require => File["$puppetmaster::gitdir/operations"],
				directory => "$puppetmaster::gitdir/operations/software",
				origin => "https://gerrit.wikimedia.org/r/p/operations/software";
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
				content => template("puppet/puppetmaster.erb");
			"/etc/apache2/ports.conf":
				owner => root,
				group => root,
				mode  => 0444,
				source => "puppet:///files/puppet/ports.conf";
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

		# monitor HTTPS on puppetmaster (port 8140, SSL, expect return code 400)
		monitor_service { "puppetmaster_https": description => "Puppetmaster HTTPS", check_command => "check_http_puppetmaster" }
	}

	# Class: puppetmaster::labs
	#
	# This class handles the Wikimedia Labs specific bits of a Puppetmaster
	class labs {
		package { "libldap-ruby1.8": ensure => latest; }
		# Use a specific revision for the checkout, to ensure we are using
		# a known and approved version of this script.
		file {
			"/usr/local/sbin/puppetsigner.py":
				ensure => link,
				target => "/usr/local/lib/instance-management/puppetsigner.py";
		}

		cron {
			"puppet_certificate_signer":
				command => "/usr/local/sbin/puppetsigner.py --scriptuser > /dev/null 2>&1",
				require => File["/usr/local/sbin/puppetsigner.py"],
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
			"/usr/local/bin/naggen":
				source => "puppet:///files/puppet/naggen";
			"/usr/local/sbin/puppetstoredconfigclean.rb":
				source => "puppet:///files/puppet/puppetstoredconfigclean.rb";
			"/usr/local/bin/decom_servers.sh":
				content => template("puppet/decom_servers.sh.erb");
			"/usr/local/bin/puppet-merge":
				source => "puppet:///files/puppet/puppet-merge";
		}

		cron {
			removeoldreports:
				command => "find /var/lib/puppet/reports -type f -ctime +1 -delete",
				user => puppet,
				hour => 4,
				minute => 27,
				ensure => present;
		}

		# Disable the decomserver cron if not running in production
		# or if running on the production puppetmaster.
		if (($::realm != 'production') or ($puppetmaster::config['thin_storeconfigs'] != true)) {
		  $decomservercron = absent
		}
		else {
		  $decomservercron = present
		}

		cron {
			decomservers:
				command => "/usr/local/bin/decom_servers.sh",
				user => root,
				minute => 17,
				ensure => $decomservercron;
		}
	}

	class geoip {
		# Including geoip::data with provider => maxmind will install a
		# cron job to download GeoIP data files from Maxmind weekly.
		# Setting data_directory will have those files downloaded into
		# data_directory.  By downloading these files into the
		# volatiledir they will be available for other nodes to get via
		# puppet by including geoip::data with provider => 'puppet'.
		class { "geoip::data":
			provider       => 'maxmind',
			data_directory => "$puppetmaster::volatiledir/GeoIP",
			environment    => "http_proxy=http://brewster.wikimedia.org:8080",  # use brewster as http proxy, since puppetmaster probably does not have internet access
		}

		cron {
			updategeoipdb:
				environment => "http_proxy=http://brewster.wikimedia.org:8080",
				command => "wget -qO - http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > $puppetmaster::volatiledir/misc/GeoIP.dat.new && mv $puppetmaster::volatiledir/misc/GeoIP.dat.new $puppetmaster::volatiledir/misc/GeoIP.dat; wget -qO - http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > $puppetmaster::volatiledir/misc/GeoIPcity.dat.new && mv $puppetmaster::volatiledir/misc/GeoIPcity.dat.new $puppetmaster::volatiledir/misc/GeoIPcity.dat",
				user => root,
				hour => 3,
				minute => 26,
				ensure => absent;  # this has been replaced by class geoip::data, included below
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

	class { "puppetmaster::ssl":
		server_name => $server_name,
		ca => $config['ca']
	}

	include scripts, geoip, gitclone

	if $is_labs_puppet_master {
		include labs
	}

}

#
# Below are classes used to configure self hosted puppet
# on labs instances. role::puppet::self (in puppet.pp)
# is the recommended class to use.  Please use it to
# include these classes.
#

# == Class puppetmaster::self
# Wrapper class for puppet::self::master
# with server => localhost.  This is
# maintained for backwards compatibility.
# Please use role::puppet::self
# in roles/puppet.pp instead.
#
class puppetmaster::self {
	class { 'puppet::self::master':
		server => 'localhost',
	}
}

# == Class puppet::self::client
# Sets up a node as a puppet client with
# $server as the puppetmaster.
#
# == Parameters
# $server - hostname of the puppetmaster.
#
class puppet::self::client($server) {
	system_role { 'puppetclient':
		description => "Puppet client of ${server}"
	}

	# Most of the defaults in puppet::self::config
	# are good for setting up a puppet client.
	class { 'puppet::self::config':
		server => $server,
	}
}

# == Class puppet::self::master
# Sets up a node as a puppetmaster.
# If server => localhost, then this node will
# be set up to only act as a puppetmaster for itself.
# Otherwise, this server will be able to act as a puppetmaster
# for any labs nodes that are configured using the puppet::self::client
# class with $server set to this nodes $::fqdn.
#
# This class will clone the operations/puppet git repository
# and set it up with proper symlinks in /etc/puppet.
#
# == Parameters
# $server - hostname of the puppetmaster.
#
class puppet::self::master($server) {
	system_role { 'puppetmaster': 
		description  => $server ? {
			'localhost' => 'Puppetmaster for itself',
			default     => 'Puppetmaster for project labs instances',
		}
	}

	# If localhost, only bind to loopback.
	$bindaddress = $server ? {
		'localhost' => '127.0.0.1',
		default => $::ipaddress,
	}

	# If localhost, only allow this node.
	# Else allow the labs subnet.
	$puppet_client_subnet = $server ? {
		'localhost' => '127.0.0.1',
		default => $::site ? {
			'pmtpa' => '10.4.0.0/21',
			'eqiad' => undef,  # eqiad does not have labs yet.
		}
	}

	# If localhost, then just name the cert 'localhost'.
	# Else certname should be the labs instanceid. ($dc comes from ldap.)
	$certname = $server ? {
		'localhost' => 'localhost',
		default => "${dc}.${::domain}"
	}

	class { 'puppet::self::config':
		is_puppetmaster      => true,
		server               => $server,
		bindaddress          => $bindaddress,
		puppet_client_subnet => $puppet_client_subnet,
		certname             => $certname,
	}
	class { 'puppet::self::gitclone':
		require => Class['puppet::self::config'],
	}
	
	package { [
		"vim-puppet",
		"puppet-el",
		"rails",
		"libsqlite3-ruby",
		"libldap-ruby1.8",
	]:
		ensure => present,
	}

	# puppetmaster is started when installed, so things must be already set
	# up by the time postinst runs; add a few require deps
	package { [ "puppetmaster", "puppetmaster-common" ]:
		ensure  => latest,
		require => [
			Package['rails'],
			Package['libsqlite3-ruby'],
			Package['libldap-ruby1.8'],
			Class['puppet::self::config'],
			Class['puppet::self::gitclone'],
		],
	}

	class { 'puppetmaster::ssl':
		server_name => $::fqdn,
		ca => true
	}

	service { 'puppetmaster':
		ensure  => 'running',
		require => Package['puppetmaster'],
	}

	include puppetmaster::scripts
}


# == Class puppet::self::config
# Configures variables and puppet config files
# for either self puppetmasters or self puppet clients.
# This inherits from base::puppet in order to override
# default puppet config files.
# 
# == Parameters
# $server - hostname of the puppetmaster.
# $is_puppetmaster - true or false. Default: false.
# $bindaddress - address to which a puppetmaster should listen.  Unused if $is_puppetmaster is false.
# $puppet_client_subnet - Network from which to allow fileserver connections.  Unused if $is_puppetmaster is false.
# $certname - Name of the puppet CA certificate.  Default: "$dc.$domain", e.g. the labs instance name:  i-00000699.pmtpa.wmflabs.
#
class puppet::self::config(
	$server,
	$is_puppetmaster = false,
	$bindaddress = undef,
	$puppet_client_subnet = undef,
	$certname = "${dc}.${::domain}") inherits base::puppet
{
	include role::ldap::config::labs

	$ldapconfig = $role::ldap::config::labs::ldapconfig
	$basedn = $ldapconfig['basedn']

	$config = {
		'dbadapter'     => 'sqlite3',
		'node_terminus' => 'ldap',
		'ldapserver'    => $ldapconfig['servernames'][0],
		'ldapbase'      => "ou=hosts,${basedn}",
		'ldapstring'    => '(&(objectclass=puppetClient)(associatedDomain=%s))',
		'ldapuser'      => $ldapconfig['proxyagent'],
		'ldappassword'  => $ldapconfig['proxypass'],
		'ldaptls'       => true
	}

	File['/etc/puppet/puppet.conf.d/10-main.conf'] {
		ensure => absent,
	}

	file { '/etc/puppet/puppet.conf.d/10-self.conf':
		require => File['/etc/puppet/puppet.conf.d'],
		owner   => root,
		group   => root,
		mode    => 0444,
		content => template('puppet/puppet.conf.d/10-self.conf.erb'),
		require => File['/etc/puppet/puppet.conf.d/10-main.conf'],
		notify  => Exec['compile puppet.conf'];
	}

	file { '/etc/puppet/fileserver.conf':
		owner    => root,
		group    => root,
		mode     => 0444,
		content  => template('puppet/fileserver-self.conf.erb'),
		ensure   => $is_puppetmaster ? {
			true    => 'file',
			default => absent,
		}
	}

}


# == Class puppet::self::gitclone
# Clones the operations/puppet repository
# for use by puppet::self::masters.
#
class puppet::self::gitclone {
	$gitdir = '/var/lib/git'

	file { $gitdir:
		ensure => directory,
		owner  => root,
		group  =>root,
	}
	file { "${gitdir}/operations":
		ensure => directory,
		owner  => root,
		group  => root,
	}
	file { "${gitdir}/labs":
		ensure => directory,
		# private repo resides here, so enforce some perms
		owner  => root,
		group  => puppet,
		mode   => 0640,
	}

	file { "${gitdir}/ssh":
		ensure  => file,
		owner   => root,
		group   => root,
		mode    => 0755,
		# FIXME: ok, this sucks. ew. ewww.
		content => "#!/bin/sh\nexec ssh -o StrictHostKeyChecking=no -i ${gitdir}/labs-puppet-key \$*\n",
		require => File["${gitdir}/labs-puppet-key"],
	}
	file { "${gitdir}/labs-puppet-key":
		ensure  => file,
		owner   => root,
		group   => root,
		mode    => 0600,
		source  => 'puppet:///private/ssh/labs-puppet-key',
	}

	git::clone { 'operations/puppet':
		directory => "${gitdir}/operations/puppet",
		branch    => 'production',
		origin    => 'https://gerrit.wikimedia.org/r/operations/puppet.git',
		require   => File["${gitdir}/operations"],
	}
	git::clone { 'labs/private':
		directory => "${gitdir}/labs/private",
		origin    => 'ssh://labs-puppet@gerrit.wikimedia.org:29418/labs/private.git',
		ssh       => "${gitdir}/ssh",
		require   => [ File["${gitdir}/labs"], File["${gitdir}/ssh"] ],
	}

	file { '/etc/puppet/private':
		ensure => link,
		target => "${gitdir}/labs/private",
		force  => true,
	}
	file { '/etc/puppet/templates':
		ensure => link,
		target => "${gitdir}/operations/puppet/templates",
		force  => true,
	}
	file { '/etc/puppet/files':
		ensure => link,
		target => "${gitdir}/operations/puppet/files",
		force  => true,
	}
	file { '/etc/puppet/manifests':
		ensure => link,
		target => "${gitdir}/operations/puppet/manifests",
		force  => true,
	}
	file { '/etc/puppet/modules':
		ensure => link,
		target => "${gitdir}/operations/puppet/modules",
		force  => true,
	}
}
