# PHP pgsql

class php::pgsql {
	require php

	package { "php5-pgsql":
		ensure => latest;
	}
}
