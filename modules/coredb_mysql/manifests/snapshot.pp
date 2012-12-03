class coredb_mysql::snapshot {

	file {
		"/usr/local/sbin/snaprotate.pl":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///modules/coredb_mysql/utils/snaprotate.pl"
	}

	cron {
		snaprotate:
			command => "/usr/local/sbin/snaprotate.pl -a swap -V tank -s data -L 100G",
			require => File["/usr/local/sbin/snaprotate.pl"],
			user => root,
			minute => 15,
			hour => '*/8',
			ensure => present;
	}
}
