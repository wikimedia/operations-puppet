# coredb_mysql required directories
class coredb_mysql::base {
	require coredb_mysql::packages

	systemuser {
		"mysql": shell => "/bin/bash"
	}

	file {
		"/a/sqldata":
			owner => mysql,
			group => mysql,
			mode => 0755,
			ensure => directory,
			require => User["mysql"];
		"/a/tmp":
			owner => mysql,
			group => mysql,
			mode => 0755,
			ensure => directory,
			require => User["mysql"];
	}
}
