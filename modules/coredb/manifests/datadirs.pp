# coredb required directories
class coredb::datadirs { 
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