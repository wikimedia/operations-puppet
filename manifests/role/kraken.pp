class role::kraken {
	include role::kraken::config
}


class role::kraken::config {
	include passwords::analytics

	include role::kraken::config::hadoop,
		role::kraken::config::hue,
		role::kraken::config::oozie,
		role::kraken::config::storm
}

class role::kraken::config::hadoop {
	$namenode_hostname = "analytics1010.eqiad.wmnet"
	$datanode_hostname = "analytics1011.eqiad.wmnet" # can pick any datanode here.
}

class role::kraken::config::hue {
	$hostname          = "analytics1027.eqiad.wmnet"
}

class role::kraken::config::oozie {
	$hostname          = "analytics1027.eqiad.wmnet"
}

class role::kraken::config::storm {
	$nimbus_host       = "analytics1002.eqiad.wmnet"
	$ui_port           = 6999
}



class role::kraken::proxy inherits role::kraken {
	# proxy listen port
	$port = 80

	# List of networks and IPs to allow
	# use of Kraken public proxy services
	# without HTTP auth password
	$whitelist = {
		"analyticsA" => "10.64.21.0/24",
		"analyticsB" => "10.64.36.0/24",
		"wmf_office" => "216.38.130.0/24",
		"diederik"   => "70.28.63.126",
		"dsc"        => "71.198.62.242",
	}

	# include kraken::proxy to
	# set up public access to
	# private Kraken web UIs.
	class { "::kraken::proxy":
		whitelist         => $whitelist,
		namenode_hostname => $role::kraken::config::hadoop::namenode_hostname,
		datanode_hostname => $role::kraken::config::hadoop::datanode_hostname,
		hue_hostname      => $role::kraken::config::hue::hostname,
		oozie_hostname    => $role::kraken::config::oozie::hostname,
		storm_hostname    => $role::kraken::config::storm::nimbus_host,
		storm_port        => $role::kraken::config::storm::ui_port,
		http_auth         => $passwords::analytics::http_proxy_auth,
	}
}
