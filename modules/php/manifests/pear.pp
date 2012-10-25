# PHP pear

class php::pear {
	require php
	require php::cli

	package { "php-pear":
		ensure => latest;
	}
}
