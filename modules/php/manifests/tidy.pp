# PHP tidy

class php::tidy {
	require php

	package { "php5-tidy":
		ensure => latest;
	}
}
