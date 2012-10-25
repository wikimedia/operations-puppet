# This class try to install all useful PHP extensions
# Please add anything you

class php::nearly_all {
	require php

	include php::cli
	include php::cgi
	include php::mysql
	include php::pgsql
	include php::sqlite
	include php::pear
	include php::dev
	include php::wikimedia

	include php::most_used

	package { [ "php-apc", "php5-gmp",
	  "php5-imagick", "php5-ldap", "php5-parsekit",
	  "php5-redis", "php5-tidy", "php5-uuid",
	  "php5-wmerrors", "php5-xmlrpc" ]:
		ensure => latest;
	}
}
