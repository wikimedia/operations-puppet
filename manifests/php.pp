# This file is for all php classes

class php5::core {
	package { "php5-common":
		ensure => latest;
	}
}

class php5::cli {
	require php5::core

	package { "php5-cli":
		ensure => latest;
	}
}

class php5::pear {
	require php5::core
	require php5::cli

	package { "php-pear":
		ensure => latest;
	}
}

class php5::dev {
	require php5::core
	require php5::pear

	package { "php5-dev":
		ensure => latest;
	}
}

class php5::pgsql {
	require php5::core

	package { "php5-pgsql":
		ensure => latest;
	}
}

class php5::mysql {
	require php5::core

	package { "php5-mysql":
		ensure => latest;
	}
}

class php5::gd {
	require php5::core

	package { "php5-gd":
		ensure => latest;
	}
}