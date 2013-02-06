# analytics servers (RT-1985)

@monitor_group { "analytics-eqiad": description => "analytics servers in eqiad" }

class role::analytics {
	system_role { "role::analytics": description => "analytics server" }
	$nagios_group = "analytics-eqiad"
	# ganglia cluster name.
	$cluster = "analytics"

	include standard,
		admins::roots,
		accounts::diederik,
		accounts::dsc,
		accounts::otto,
		accounts::dartar,
		accounts::erosen,
		accounts::olivneh,
		accounts::erik,
		accounts::dandreescu,
		accounts::spetrea # per RT4402

	sudo_user { [ "diederik", "dsc", "otto" ]: privileges => ['ALL = (ALL) NOPASSWD: ALL'] }

	# Install Sun/Oracle Java JDK on analytics cluster
	java { "java-6-oracle": 
		distribution => 'oracle',
		version      => 6,
	}

	# Hadoop and Hue use LDAP to authenticate users, and require this
	#
	# TODO:  Try out Hadoop LDAP user group mapping, so we don't need
	# NSS LDAP.
    class { "role::ldap::client::labs":
            ldapincludes =>  ['openldap', 'utils', 'nss'],
    }

	# We want to be able to geolocate IP addresses
	include geoip

	# udp-filter is a useful thing!
	include misc::udp2log::udp_filter
}

# proxy web access to Kraken web UIs
class role::analytics::proxy inherits role::analytics {
	include misc::analytics::proxy
}

# front end interfaces for Kraken and Hadoop
class role::analytics::frontend inherits role::analytics {
	# include a mysql database for Sqoop and Oozie
	# with the datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
}
