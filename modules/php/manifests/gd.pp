# PHP gd

class php::gd {
	require php

	package { "php5-gd":
		ensure => latest;
	}
}
