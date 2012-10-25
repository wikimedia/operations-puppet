# PHP luasandbox

class php::luasandbox {
	require php

	package { "php-luasandbox":
		ensure => latest;
	}
}
