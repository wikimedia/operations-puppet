#  Labs/testing RT with Apache
#
class role::request-tracker-apache::labs {
	include passwords::misc::rt

	$datadir = "/srv/mysql"

	class { "misc::rt-apache::server":
		dbuser => $passwords::misc::rt::rt_mysql_user,
		dbpass => $passwords::misc::rt::rt_mysql_pass,
		site => $::fqdn,
		datadir => $datadir,
	}

	class { 'mysql::server':
		config_hash => {
			'datadir' => $datadir,
		}
	}

	exec { 'rt-db-initialize':
		command => "/bin/echo '' | /usr/sbin/rt-setup-database --action init --dba root --prompt-for-dba-password",
		require => Class['misc::rt-apache::server', 'mysql::server'],
		unless  => '/usr/bin/mysqlshow rt4';
	}
}

#  Production RT with Apache
#
class role::request-tracker-apache::production {
	include passwords::misc::rt

	class { "misc::rt-apache::server":
		site => 'rt.wikimedia.org',
		dbhost => 'db1001.eqiad.wmnet',
		dbport => '',
		dbuser => $passwords::misc::rt::rt_mysql_user,
		dbpass => $passwords::misc::rt::rt_mysql_pass,
	}
}
