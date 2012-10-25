# PHP cli

class php::cli {
	require php

	package { "php5-cli":
		ensure => latest;
	}
}
