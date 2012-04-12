# mysql.pp

# Virtual resource for the monitoring server
@monitor_group { "es": description => "External Storage" }
@monitor_group { "mysql_pmtpa": description => "pmtpa mysql core" }
@monitor_group { "mysql_eqiad": description => "eqiad mysql core" }

# TODO should really be named mysql-server, or mysql::server
class mysql {
	monitor_service { "mysql disk space": description => "MySQL disk space", check_command => "nrpe_check_disk_6_3", critical => true }

	package { [ lvm2, maatkit ]:
		ensure => "installed";
	}

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		package { ["xtrabackup", "percona-toolkit", "libaio1" ]:
			ensure => latest;
		}
	} elsif $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "8.04") == 0 {
		package { "percona-toolkit":
			ensure => latest;
		}
	}

	#######################################################################
	### MASTERS - make sure to update here whenever changing replication
	#######################################################################
	if $hostname =~ /^db(38|13|31|35|39|43|37|48)|blondel$/ {
		$master = "true"
		$writable = "true"
	} else {
		$master = "false"
	}

	#######################################################################
	### LVM snapshot hosts - currently only puppet managed in eqiad
	#######################################################################
	if $hostname =~ /^db(24|25|26|32|33|44|46|1005|1007|1018|1020|1022|1033|1035)$/ {
		$snapshot_host = true
	}

	#######################################################################
	### Cluster Definitions - update if changing / building new dbs
	#######################################################################
	if $hostname =~ /^db(12|32|36|38|42|52|53|1001|1017|1033|1043|1047)$/ {
		$db_cluster = "s1"
	}
	elsif $hostname =~ /^db(13|24|30|54|1002|1018|1034)$/ {
		$db_cluster = "s2"
	}
	elsif $hostname =~ /^db(11|25|34|39|1003|1019|1035)$/ {
		$db_cluster = "s3"
	}
	elsif $hostname =~ /^db(22|31|33|51|1004|1020|1038)$/ {
		$db_cluster = "s4"
	}
	elsif $hostname =~ /^db(35|44|45|55|1005|1021|1039)$/ {
		$db_cluster = "s5"
	}
	elsif $hostname =~ /^db(43|46|47|50|1006|1022|1040)$/ {
		$db_cluster = "s6"
	}
	elsif $hostname =~ /^db(16|18|26|37|56|1007|1024|1041)$/ {
		$db_cluster = "s7"
	}
	elsif $hostname =~ /^blondel|bellin$/ {
		$db_cluster = "m1"
	}
	elsif $hostname =~ /^db(1008|1025)$/ {
		$db_cluster = "fundraisingdb"
		if $hostname =~ /^db1008$/ {
			include role::db::fundraising::master
			$writable = "true"
		}
		elsif $hostname =~ /^db1025$/ {
			include role::db::fundraising::slave
		}
	}
	elsif $hostname =~ /^db(48|49|1042|1048)$/ {
		$db_cluster = "otrsdb"
		$skip_name_resolve = "false"
	}
	else {
		$db_cluster = undef
	}

	if ($db_cluster) { 
		file { "/etc/db.cluster":
			content => "${db_cluster}";
		}
		# this is for the pt-heartbeat daemon, which needs super privs
		# to write to read_only=1 databases.
		if ($db_cluster !~ /fund/) {
			include passwords::misc::scripts
			file {
				"/root/.my.cnf":
					owner => root,
					group => root,
					mode => 0400,
					content => template("mysql/root.my.cnf.erb");
				"/etc/init.d/pt-heartbeat":
					owner => root,
					group => root,
					mode => 0555,
					source => "puppet:///files/mysql/pt-heartbeat.init";
			}
			service { pt-heartbeat:
				require => [ File["/etc/init.d/pt-heartbeat"], Package[percona-toolkit] ],
				subscribe => File["/etc/init.d/pt-heartbeat"],
				ensure => running,
				hasstatus => false;
			}
			include mysql::monitor::percona
		}
	}

	file { "/usr/local/bin/master_id.py":
		owner => root,
		group => root,
		mode => 0555,
		source => "puppet:///files/mysql/master_id.py"
	}

	#######################################################################
	### Research DB Definitions - should also belong to a cluster above
	#######################################################################
	if $hostname =~ /^db(42|1047)$/ {
		$research_dbs = true
		$writable = "true"
	}

	class packages {
		file { "/etc/apt/sources.list.d/wikimedia-mysql.list":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/mysql/wikimedia-mysql.list"
		}

		package { [ 'mysql-client-5.1', 'mysql-server-core-5.1', 'mysql-server-5.1', 'libmysqlclient16' ]:
			ensure => "5.1.53-fb3753-wm1",
			require => File["/etc/apt/sources.list.d/wikimedia-mysql.list"];
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

	# this is for checks from the percona-nagios-checks project
	# http://percona-nagios-checks.googlecode.com
	class monitor::percona::files {
		include passwords::nagios::mysql
		$mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

		file {
			"${nagios_config_dir}/nrpe.d/nrpe_percona.cfg":
				owner => root,
				group => nagios,
				mode => 0440,
				content => template("nagios/nrpe_percona.cfg.erb"),
				notify => Service[nagios-nrpe-server];
			"/usr/lib/nagios/plugins/percona":
				ensure => directory,
				owner => root,
				group => root,
				mode => 0755;
			"/usr/lib/nagios/plugins/percona/check_lvs":
				source => "puppet:///files/nagios/percona/check_lvs",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysql_deadlocks":
				source => "puppet:///files/nagios/percona/check_mysql_deadlocks",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysql_idle_transactions":
				source => "puppet:///files/nagios/percona/check_mysql_idle_transactions",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysql_recent_restart":
				source => "puppet:///files/nagios/percona/check_mysql_recent_restart",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysql_slave_delay":
				source => "puppet:///files/nagios/percona/check_mysql_slave_delay",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysql_slave_running":
				source => "puppet:///files/nagios/percona/check_mysql_slave_running",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysql_unauthenticated_users":
				source => "puppet:///files/nagios/percona/check_mysql_unauthenticated_users",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysqld_deleted_files":
				source => "puppet:///files/nagios/percona/check_mysqld_deleted_files",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysqld_file_ownership":
				source => "puppet:///files/nagios/percona/check_mysqld_file_ownership",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysqld_frm_ibd":
				source => "puppet:///files/nagios/percona/check_mysqld_frm_ibd",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/check_mysqld_pid_file":
				source => "puppet:///files/nagios/percona/check_mysqld_pid_file",
				owner => root,
				group => root,
				mode => 0555;
			"/usr/lib/nagios/plugins/percona/utils.sh":
				source => "puppet:///files/nagios/percona/utils.sh",
				owner => root,
				group => root,
				mode => 0555;
		}
	}

	class monitor::percona inherits mysql {
		$crit = $master
		require "mysql::monitor::percona::files"

		monitor_service { "mysqld": description => "mysqld processes", check_command => "nrpe_check_mysqld", critical => $crit }
		monitor_service { "mysql recent restart": description => "MySQL Recent Restart", check_command => "nrpe_check_mysql_recent_restart", critical => $crit }
		monitor_service { "full lvs snapshot": description => "Full LVS Snapshot", check_command => "nrpe_check_lvs", critical => false }
		monitor_service { "mysql idle transaction": description => "MySQL Idle Transactions", check_command => "nrpe_check_mysql_idle_transactions", critical => false }
		monitor_service { "mysql slave running": description => "MySQL Slave Running", check_command => "nrpe_check_mysql_slave_running", critical => false }
		monitor_service { "mysql replication heartbeat": description => "MySQL Replication Heartbeat", check_command => "nrpe_check_mysql_slave_heartbeat", critical => false }
		monitor_service { "mysql slave delay": description => "MySQL Slave Delay", check_command => "nrpe_check_mysql_slave_delay", critical => false }
	}

	class monitor::percona::es inherits mysql {
		if $db::es::mysql_role == "master" {
			$crit = true
		}
		require "mysql::monitor::percona::files"

		monitor_service { "mysqld": description => "mysqld processes", check_command => "nrpe_check_mysqld", critical => $crit }
		monitor_service { "mysql recent restart": description => "MySQL Recent Restart", check_command => "nrpe_check_mysql_recent_restart", critical => $crit }
		monitor_service { "mysql slave running": description => "MySQL Slave Running", check_command => "nrpe_check_mysql_slave_running", critical => false }
		monitor_service { "mysql slave delay": description => "MySQL Slave Delay", check_command => "nrpe_check_mysql_slave_delay", critical => false }
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

	class conf inherits mysql {
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
			},
			"m1" => {
				"innodb_log_file_size" => "500M"
			}
		}

		if $db_cluster {
			$ibsize = $db_clusters[$db_cluster]["innodb_log_file_size"]
		} else { 
			$ibsize = "500M"
		}

		# enable innodb_file_per_table if it's a fundraising or otrs database
		if $db_cluster =~ /^(fundraisingdb|otrsdb)$/ {
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
			if $writable { 
				$read_only = "false"
			} else { 
				$read_only = "true"
			}
		}

		if ! $skip_name_resolve { 
			$skip_name_resolve = "true"
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

		if $snapshot_host {
			cron { snaprotate:
				command => "/usr/local/sbin/snaprotate.pl -a swap -V tank -s data -L 100G",
				require => File["/usr/local/sbin/snaprotate.pl"],
				user => root,
				minute => 15,
				hour => '*/8',
				ensure => present;
			}
		} else { 
			cron { snaprotate:
				ensure => absent;
			}
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

	include mysql::ganglia,
		mysql::monitor::percona::files

	# TODO do we want to have a class for PHP clients (php5-mysql) as well
	# and rename this to mysql::client-cli?
	class client {
		package { "mysql-client-5.1":
			ensure => latest;
		}
	}
}
