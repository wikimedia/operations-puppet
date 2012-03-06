class owa::database::iptables-purges {

	require "iptables::tables"

	# The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "database_deny_all": service => "mysql" }

	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever

}

class owa::database::iptables-accepts {

	require "owa::database::iptables-purges"

	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "database_owa1": service => "mysql", source => "208.80.152.112", jump => "ACCEPT" }
	iptables_add_service{ "database_owa2": service => "mysql", source => "208.80.152.113", jump => "ACCEPT" }
	iptables_add_service{ "database_owa3": service => "mysql", source => "208.80.152.114", jump => "ACCEPT" }
	iptables_add_service{ "database_spence": service => "mysql", source => "208.80.152.161", jump => "ACCEPT" }
	iptables_add_service{ "database_neon": service => "mysql", source => "208.80.154.14", jump => "ACCEPT" }

}

class owa::database::iptables-drops {

	require "owa::database::iptables-accepts"

	iptables_add_service{ "database_deny_all": service => "mysql", jump => "DROP" }

}

class owa::database::iptables  {

	# We use the following requirement chain:
	# iptables -> iptables::drops -> iptables::accepts -> iptables::purges
	#
	# This ensures proper ordering of the rules
	require "owa::database::iptables-drops"

	# This exec should always occur last in the requirement chain.
	iptables_add_exec{ "database": service => "owa_database" }

}

class owa::iptables-purges {

	require "iptables::tables"

	# The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
	iptables_purge_service{ "deny_all": service => "memcached" }

	# When removing or modifying a rule, place the old rule here, otherwise it won't
	# be purged, and will stay in the iptables forever

}

class owa::iptables-accepts {

	require "owa::iptables-purges"

	# Rememeber to place modified or removed rules into purges!
	iptables_add_service{ "owa1": service => "memcached", source => "208.80.152.112", jump => "ACCEPT" }
	iptables_add_service{ "owa2": service => "memcached", source => "208.80.152.113", jump => "ACCEPT" }
	iptables_add_service{ "owa3": service => "memcached", source => "208.80.152.114", jump => "ACCEPT" }
	iptables_add_service{ "spence": service => "memcached", source => "208.80.152.161", jump => "ACCEPT" }
	iptables_add_service{ "neon": service => "memcached", source => "208.80.154.14", jump => "ACCEPT" }

}

class owa::iptables-drops {

	require "owa::iptables-accepts"

	iptables_add_service{ "deny_all": service => "memcached", jump => "DROP" }

}

class owa::iptables  {

	# We use the following requirement chain:
	# iptables -> iptables::drops -> iptables::accepts -> iptables::purges
	#
	# This ensures proper ordering of the rules
	require "owa::iptables-drops"

	# This exec should always occur last in the requirement chain.
	iptables_add_exec{ "${hostname}": service => "owa" }

}

class owa::processing {

	package { [ 'subversion', 'php5', 'php5-cli', 'php-apc' ,'php5-mysql', 'mysql-client', 'apache2', 'php5-memcache' ]:
		ensure => latest;
	}

	service { apache2:
		require => Package[apache2],
		subscribe => File["/etc/apache2/sites-available/owa"],
		ensure => running;
	}
	
	file {
		"/srv/owa-data":
			owner => www-data,
			group => wikidev,
			mode => 0775,
			ensure => directory;
		"/usr/local/owa":
			owner => root,
			group => root,
			mode => 0755,
			ensure => directory;
		"/usr/local/owa/admin":
			owner => root,
			group => root,
			mode => 0755,
			require => File["/usr/local/owa"],
			ensure => directory;
		"/usr/local/owa/deployment":
			owner => root,
			group => wikidev,
			mode => 0775,
			require => File["/usr/local/owa"],
			ensure => directory;
		"/usr/local/owa/resources":
			owner => root,
			group => wikidev,
			mode => 0775,
			require => File["/usr/local/owa"],
			ensure => directory;
		"/usr/local/owa/admin/processFileQueue.sh":
			owner => root,
			group => root,
			mode => 0755,
			require => File["/usr/local/owa/admin"],
			source => "puppet:///files/owa/processFileQueue.sh";
		"/usr/local/owa/admin/processDBQueue.sh":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/owa/processDBQueue.sh";
		"/etc/apache2/sites-available/owa":
                        owner => root,
                        group => root,
                        mode => 0755,
                        source => "puppet:///files/owa/owa-apache";
		"/etc/apache2/sites-enabled/000-default":
			ensure => absent;
	}

	apache_site{ $title: name => "owa" }
	apache_module{ $title: name => "ssl" }

	cron {
		processFileQueue:
			command => "/usr/local/owa/admin/processFileQueue.sh >/dev/null 2>&1",
			require => File["/usr/local/owa/admin/processFileQueue.sh"],
			user => root,
			minute => [0,5,10,15,20,25,30,35,40,45,50,55];
		processDBQueue:
			command => "/usr/local/owa/admin/processDBQueue.sh >/dev/null 2>&1",
			require => File["/usr/local/owa/admin/processDBQueue.sh"],
			user => root,
			minute => [5,15,25,35,45,55];
	}

	include "owa::iptables"
	include "certificates::star_wikimedia_org"

}

class owa::database {

	package { [ "mysql-server" ]:
		ensure => latest;
	}

	include "owa::database::iptables"
}
