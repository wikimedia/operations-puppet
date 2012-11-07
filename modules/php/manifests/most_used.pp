# PHP most used extensions

class php::most_used {
	require php

	include php::cli
	include php::mysql
	include php::pear
	include php::gd

	package { [ "php5-curl", "php5-mcrypt",
	  "php5-intl" ]:
		ensure => latest;
	}
}
