# PHP most used extensions

class php::most_used {
	require php

	include php::cli
	include php::mysql
	include php::pear

	package { [ "php5-curl", "php5-mcrypt",
	  "php5-intl", "php5-gd" ]:
		ensure => latest;
	}
}
