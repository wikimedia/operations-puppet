# PHP parsekit

class php::parsekit {
	require php

	package { "php5-parsekit":
		ensure => latest;
	}
}
