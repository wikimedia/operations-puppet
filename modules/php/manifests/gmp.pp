# PHP gmp

class php::gmp {
	require php

	package { "php5-gmp":
		ensure => latest;
	}
}
