# == Class haproxy
# Installs haproxy and ensures that it is running.
# Note: This class does not currently manage haproxy.cfg.
#
class haproxy
{
	package { "haproxy":
		ensure => "installed"
	}

	service { "haproxy":
		ensure    => running,
		enable    => true,
	}
}