# mysql.pp

# Virtual resource for the monitoring server
#@monitor_group { "mysql": description => "MySQL core" }
@monitor_group { "es": description => "External Storage" }


class mysql {
	monitor_service { "mysql disk space": description => "MySQL disk space", check_command => "nrpe_check_disk_6_3", critical => true }

	package { [ lvm2, maatkit ]:
		ensure => "installed";
	}

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") >= 0 {
		package { xtrabackup:	
			ensure => "installed";
		}
	}

	class ganglia {

		include passwords::ganglia
		$ganglia_mysql_pass = $passwords::ganglia::ganglia_mysql_pass

		# Ganglia
		package { python-mysqldb:
			ensure => present;
		}

		# FIXME: this belongs in ganglia.pp, not here.
		if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "8.04") == 0 {
			file {
				"/etc/ganglia":
					owner => root,
					group => root,
					mode => 0755,
					ensure => directory;
				"/etc/ganglia/conf.d":
					owner => root,
					group => root,
					mode => 0755,
					ensure => directory;
				"/usr/lib/ganglia/python_modules":
					owner => root,
					group => root,
					mode => 0755,
					ensure => directory;
			}
		}
		file {
			"/usr/lib/ganglia/python_modules/DBUtil.py":
				require => File["/usr/lib/ganglia/python_modules"],
				source => "puppet:///files/ganglia/plugins/DBUtil.py",
				notify => Service[gmond];
			"/usr/lib/ganglia/python_modules/mysql.py":
				require => File["/usr/lib/ganglia/python_modules"],
				source => "puppet:///files/ganglia/plugins/mysql.py",
				notify => Service[gmond];
			"/etc/ganglia/conf.d/mysql.pyconf":
				require => File["/usr/lib/ganglia/python_modules"],
				content => template("mysql/mysql.pyconf.erb"),
				notify => Service[gmond];
		}
	}

	class mysqluser {
		user { 
			"mysql": ensure => "present",
		}
	}

	class datadirs { 
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

	class conf {
		$db_clusters = {
			"fundraisingdb" => { 
				"innodb_log_file_size" => "500M"
			},
			"otrsdb" => { 
				"innodb_log_file_size" => "500M"
			},
			"s1" => { 
				"innodb_log_file_size" => "2000M"
			},
			"s2" => { 
				"innodb_log_file_size" => "2000M"
			},
			"s3" => { 
				"innodb_log_file_size" => "500M"
			},
			"s4" => { 
				"innodb_log_file_size" => "2000M"
			},
			"s5" => { 
				"innodb_log_file_size" => "1000M"
			},
			"s6" => { 
				"innodb_log_file_size" => "500M"
			},
			"s7" => { 
				"innodb_log_file_size" => "500M"
			}
		}

		if $db_cluster { 
			$ibsize = $db_clusters[$db_cluster]["innodb_log_file_size"]
		} else { 
			$ibsize = "500M"
		}

		# enable innodb_file_per_table if it's a fundraising or otrs database
		if $db_cluster ==~ /^(fundraisingdb|otrsdb)$/ {
			$innodb_file_per_table = "true"
		} else {
			$innodb_file_per_table = "false"
		}
		
		# collect all the changes to the dbs used by the summer researchers

		# FIXME: please qualify these globals with something descriptive, e.g. $mysql_read_only
		# FIXME: defaults aren't set, so template expansion is currently broken
		if $research_dbs {
			$disable_binlogs = "true"
			$read_only = "false"
			$long_timeouts = "true"
			$enable_unsafe_locks = "true"
			$large_slave_trans_retries = "true"
		} else {
			$disable_binlogs = "false"
			$long_timeouts = "false"
			$enable_unsafe_locks = "false"
			$large_slave_trans_retries = "false"
		}

		if $writable { 
			$read_only = "false"
		} else { 
			$read_only = "true"
		}

		file { "/etc/my.cnf":
			content => template("mysql/prod.my.cnf.erb")
		}
		file { "/etc/mysql/my.cnf":
			source => "puppet:///files/mysql/empty-my.cnf"
		}

		file {
			"/usr/local/sbin/snaprotate.pl":
				owner => root,
				group => root,
				mode => 0555,
				source => "puppet:///files/mysql/snaprotate.pl"
		}
	}

	class mysqlpath {
		file { "/etc/profile.d/mysqlpath.sh":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/mysql/mysqlpath.sh"
		}
	}

	include mysql::ganglia
}
