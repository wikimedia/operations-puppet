# MariaDB - for LABS ONLY

class misc::mariadb($mariadb_version="5.3") {

	class repository {

		if $realm == "labs" {

			system_role { "misc::mariadb::repo": description => "host which uses external MariaDB repository" }

			file { "/etc/apt/sources.list.d/mariadb${mariadb_version}.list":
				ensure	=> present,
				mode	=> "0444",
				owner	=> root,
				group	=> root,
				source	=> "puppet:///files/apt/mariadb${mariadb_version}.list";
			}

			apt::key { "MariaDB":
				keyid	=> "1BB943DB",
				ensure	=> present;
			}

			exec { ["mariadb_update_apt"]:
				command => "/usr/bin/apt-get update",
				logoutput => true,
				onlyif => "/bin/false",
				subscribe => File["/etc/apt/sources.list.d/mariadb${mariadb_version}.list"];
			}
		}

	}

	class client {
		system_role { "misc::mariadb::client": description => "MariaDB client" }

		package { "mariadb-client-${mariadb_version}":
			ensure	=> latest,
			require => Class['misc::mariadb::repository'];
		}
	}

	class server {
		system_role { "misc::mariadb::server": description => "MariaDB server" }

		package { "mariadb-server-${mariadb_version}":
			ensure	=> latest,
			require => Class['misc::mariadb::repository'];
		}
	}
}
