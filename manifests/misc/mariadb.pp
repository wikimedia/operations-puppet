# MariaDB - for LABS ONLY

class misc::mariadb($version="5.3") {
	system_role { "misc::mariadb": description => "host uses external MariaDB repository" }

	class repository {

		file { "/etc/apt/sources.list.d/mariadb${version}.list":
			ensure	=> present,
			mode	=> "0444",
			owner	=> root,
			group	=> root,
			source	=> "puppet:///files/apt/mariadb${version}.list";
		}

		apt::key { "MariaDB":
			keyid	=> "1BB943DB",
			ensure	=> present;
		}

		exec { ["mariadb_update_apt"]:
			command => "/usr/bin/apt-get update",
			logoutput => true,
			onlyif => "/bin/false",
			subscribe => File["/etc/apt/sources.list.d/mariadb${version}.list"];
		}
	}

	class client {
		system_role { "misc::mariadb::client": description => "MariaDB client" }
	
		require repository

		package { "mariadb-client-${version}":
			ensure	=> latest;
		}
	}

	class server {
		system_role { "misc::mariadb::server": description => "MariaDB server" }	

		require repository

		package { "mariadb-server-${version}":
			ensure	=> latest;
		}
	}
}
