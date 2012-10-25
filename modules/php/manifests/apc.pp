# PHP apc

class php::apc {
	require php

	package { "php-apc":
		ensure => latest;
	}
}
