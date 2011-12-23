# MariaDB - for LABS ONLY

class misc::mariadb($version="5.3") {
	system_role { 'misc::mariadb': description => 'MariaDB host' }

	file { '/etc/apt/sources.list.d/mariadb${version}.list':
		ensure	=> present,
		mode	=> '0444',
		owner	=> root,
		group	=> root,
		source	=> 'puppet:///files/apt/mariadb${version}.list';
	}

	apt::key { 'MariaDB':
		keyid	=> '1BB943DB',
		ensure	=> present;
	}

	exec { ["mariadb_update_apt"]:
		command => '/usr/bin/apt-get update',
		require => File["/etc/apt/sources.list.d/mariadb${version}.list"]
	}

	class client {
		package { 'mariadb-client-${version}':
			ensure	=> latest,
			require => File["/etc/apt/sources.list.d/mariadb${version}.list"];
		}
	}

	class server {
		package { 'mariadb-server-${version}':
			ensure	=> latest,
			require => File["/etc/apt/sources.list.d/mariadb${version}.list"];
		}
	}
}
