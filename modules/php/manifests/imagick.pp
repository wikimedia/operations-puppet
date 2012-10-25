# PHP imagick

class php::imagick {
	require php

	package { "php5-imagick":
		ensure => latest;
	}
}
