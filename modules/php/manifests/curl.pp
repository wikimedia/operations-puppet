# PHP curl

class php::curl {
	require php

	package { "php5-curl":
		ensure => latest;
	}
}
