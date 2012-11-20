# analytics.pp

# Contains classes and definitions for configuring
# the Kraken Analytics cluster nodes.
#
# NOTE:  This may be moved to an analytics module.

# == Class analytics::db::mysql
# 
class analytics::db::mysql {
	# install a mysql server with the
	# datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
}
