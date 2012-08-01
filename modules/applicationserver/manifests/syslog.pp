# syslog instance and configuration for applicationservers
class applicationserver::syslog {
	require base::remote-syslog

	file {
		"/etc/rsyslog.d/40-appserver.conf":
			require => Package[rsyslog],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/rsyslog/40-appserver.conf",
			ensure => present;
		"/usr/local/bin/apache-syslog-rotate":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/apache-syslog-rotate",
			ensure => present;
	}
}