class snapshots::packages {

	package { [ 'subversion', 'php5', 'php5-cli', 'php5-mysql', 'mysql-client-5.1', 'p7zip-full', 'libicu42', 'wikimedia-php5-utfnormal' ]:
		ensure => latest;
	}
}

class snapshots::files {
	require snapshots::packages

	file { 'snapshot-php5-cli-ini':
		path => "/etc/php5/cli/php.ini",
		mode => 0644,
		owner => root,
		group => root,
		source => "puppet:///files/php/php.ini.cli.snaps.$lsbdistcodename",
		ensure => present;
	}

	file { 'snapshot-fss-ini':
		path => "/etc/php5/conf.d/fss.ini",
		mode => 0644,
		owner => root,
		group => root,
		source => "puppet:///files/php/fss.ini.snaps.$lsbdistcodename",
		ensure => present;
	}

	file { 'snapshot-sudoers':
		path => "/etc/sudoers.d/appserver",
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.appserver",
		ensure => present;
	}

}

class snapshots::sync {
	require snapshots::packages

        exec { 'snapshot-trigger-mw-sync':
                command => '/bin/true',
                notify => Exec['mw-sync'],
                unless => "/usr/bin/test -d /usr/local/apache/common-local";
        }
}

class snapshots::noapache {
	service { 'noapache':
		name => "apache2",
		enable => false,
		ensure => stopped;
	}
}

