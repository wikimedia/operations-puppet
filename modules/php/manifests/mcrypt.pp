# PHP mcrypt

class php::mcrypt {
	require php

	package { "php5-mcrypt":
		ensure => latest;
	}
}
