# == Class role::kraken
#
class role::kraken {
	include role::kraken::config
}


# == Class role::kraken::config
# Config variables for Kraken.
#
class role::kraken::config {
	include passwords::analytics

	case $::realm {
		"production": {
			$hadoop_namenode_hostname = "analytics1010.eqiad.wmnet"
			$hadoop_datanode_hostname = "analytics1011.eqiad.wmnet" # can pick any datanode here.
			$hue_hostname             = "analytics1027.eqiad.wmnet"
			$oozie_hostname           = "analytics1027.eqiad.wmnet"
			$storm_nimbus_hostname    = "analytics1002.eqiad.wmnet"
			$storm_ui_port            = 6999
		}
		default: {
			$hadoop_namenode_hostname = "localhost"
			$hadoop_datanode_hostname = "localhost" # can pick any datanode here.
			$hue_hostname             = "localhost"
			$oozie_hostname           = "localhost"
			$storm_nimbus_hostname    = "localhost"
			$storm_ui_port            = 6999
		}
	}
}


# == Class role::kraken::public
# Installs an HTTPS proxy with HTTP authentication,
# as well as a (temporary) name based proxy to
# Kraken web UI services on their backend locations.
#
class role::kraken::public inherits role::kraken {
	# The *-kraken.wikimedia.org URLs that will be used
	# by kraken::proxy to map domain names to internal
	# Kraken Web UI host:ports do not yet have real DNS
	# entries.  For now include /etc/host entries
	# to localhost.  This allows the (Apache 443) SSL proxy
	# to proxy to (haproxy 81) name based proxy on localhost.
	file_line { "kraken_public_urls":
		path => "/etc/hosts",
		line => "127.0.0.1 namenode-kraken.wikimedia.org datanode-kraken.wikimedia.org jobs-kraken.wikimedia.org history-kraken.wikimedia.org hue-kraken.wikimedia.org oozie-kraken.wikimedia.org storm-kraken.wikimedia.org",
	}

	class { "::kraken::https":
		http_auth => $passwords::analytics::http_proxy_auth,
	}

	# List of networks and IPs to allow
	# use of Kraken public proxy services
	# without HTTP auth password.
	#
	# NOTE:  This is unused for now.
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
		namenode_hostname => $role::kraken::config::hadoop_namenode_hostname,
		datanode_hostname => $role::kraken::config::hadoop_datanode_hostname,
		hue_hostname      => $role::kraken::config::hue_hostname,
		oozie_hostname    => $role::kraken::config::oozie_hostname,
		storm_hostname    => $role::kraken::config::storm_nimbus_hostname,
		storm_port        => $role::kraken::config::storm_ui_port,
	}
}
