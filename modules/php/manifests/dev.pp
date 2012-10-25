# PHP dev

class php::dev {
	require php
	require php::pear

	package { "php5-dev":
		ensure => latest;
	}
}
