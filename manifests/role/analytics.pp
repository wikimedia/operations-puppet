# analytics servers (RT-1985)

@monitor_group { "analytics-eqiad": description => "analytics servers in eqiad" }

class role::analytics {
	system_role { "role::analytics": description => "analytics server" }
	$nagios_group = "analytics-eqiad"
	# ganglia cluster name.
	$cluster = "analytics"

	include standard
	include admins::roots

	# Include stats system user to
	# run automated jobs and for file
	# ownership.
	include misc::statistics::user

	# include analytics user accounts
	include role::analytics::users

	# Install Sun/Oracle Java JDK on analytics cluster
	java { "java-6-oracle":
		distribution => 'oracle',
		version      => 6,
	}

	# We want to be able to geolocate IP addresses
	include geoip

	# udp-filter is a useful thing!
	include misc::udp2log::udp_filter
}

class role::analytics::users {
	# Analytics user accounts will be added to the
	# 'stats' group which gets created by this class.
	require misc::statistics::user

	include accounts::diederik,
		accounts::dsc,
		accounts::otto,
		accounts::dartar,
		accounts::erosen,
		accounts::olivneh,
		accounts::erik,
		accounts::milimetric,
		accounts::spetrea # per RT4402

	# add Analytics team members to the stats group so they can
	# access data group owned by 'stats'.
	User<|title == milimetric|>  { groups +> [ "stats" ] }
	User<|title == dartar|>      { groups +> [ "stats" ] }
	User<|title == dsc|>         { groups +> [ "stats" ] }
	User<|title == diederik|>    { groups +> [ "stats" ] }
	User<|title == erik|>        { groups +> [ "stats" ] }
	User<|title == erosen|>      { groups +> [ "stats" ] }
	User<|title == olivneh|>     { groups +> [ "stats" ] }
	User<|title == otto|>        { groups +> [ "stats" ] }
	User<|title == spetrea|>     { groups +> [ "stats" ] }

	# Diederik, David and Otto have sudo privileges on Analytics nodes.
	sudo_user { [ "diederik", "dsc", "otto" ]: privileges => ['ALL = (ALL) NOPASSWD: ALL'] }
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
