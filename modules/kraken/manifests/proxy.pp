# == Class kraken::proxy
#
# Includes haproxy module and installs
# installs custom haproxy.cfg file.
# This allows public access to
# privately hosted Kraken web UIs.
#
# NOTE:  This class will probably change soon
# to be replaced with a better method
# of accessing internal Kraken web UIs.
#
class kraken::proxy(
	$namenode_hostname,
	$datanode_hostname,
	$hue_hostname,
	$oozie_hostname,
	$storm_hostname,
	$storm_port,
	$bind      = "127.0.0.1:81",
	$whitelist = {},
	$http_auth = {}
)
{
	include haproxy

	file { "/etc/haproxy/haproxy.cfg":
		content => template("kraken/haproxy.cfg.erb"),
		notify  => Service["haproxy"],
	}
}