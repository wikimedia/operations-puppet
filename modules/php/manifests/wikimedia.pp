# PHP wikimedia extensions

class php::wikimedia {
	require php

	package { [ "php-wikidiff2", "php-luasandbox" ]:
		ensure => latest;
	}
}
