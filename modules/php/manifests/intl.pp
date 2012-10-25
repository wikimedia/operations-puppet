# PHP intl

class php::intl {
	require php

	package { "php5-intl":
		ensure => latest;
	}
}
