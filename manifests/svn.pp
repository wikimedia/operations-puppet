class svn::server {
	system_role { "svn::server": description => "public SVN server" }

	require "svn::groups::svn"

	include webserver::php5

	package { [ 'libsvn-notify-perl', 'python-subversion',
			'libapache2-svn', 'python-pygments' ]:
		ensure => latest;
	}

	file {
		'/usr/local/bin/sillyshell':
			owner => 'root',
			group => 'root',
			mode  => '0555',
			source => 'puppet:///files/svn/sillyshell';
		'/etc/apache2/sites-available/svn':
			owner => 'root',
			group => 'root',
			mode => '0444',
			source => 'puppet:///files/apache/sites/svn.wikimedia.org',
			notify => Service[apache2];
		'/srv/org/wikimedia/svn':
			ensure => directory,
			source => 'puppet:///files/svn/docroot',
			owner => 'root',
			group => 'svnadm',
			mode  => '0664',
			recurse => true;
		'/var/cache/svnusers':
			ensure => directory,
			owner => 'www-data',
			group => 'www-data',
			mode => '0755';
		'/svnroot':
			ensure => directory,
			owner => 'root',
			group => 'svn',
			mode => '0775';
	}

	apache_site { "svn": name => "svn", prefix => "000-" }

	monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!svn.wikimedia.org" }

	cron { 'svnuser_generation':
			command => '(cd /var/cache/svnusers && svn up) > /dev/null 2>&1',
			user => 'www-data',
			hour => 0,
			minute => 0;
	}

	exec { '/usr/bin/svn co file:///svnroot/mediawiki/USERINFO svnusers':
		creates => '/var/cache/svnusers/.svn',
		cwd => '/var/cache',
		user => 'www-data',
		require => File['/var/cache/svnusers'];
	}

	class viewvc {
		require svn::server

		package { [ 'viewvc', 'graphviz', 'doxygen' ]:
			ensure => latest;
		}

		file {
			"/etc/apache2/svn-authz":
				owner => 'root',
				group => 'root',
				mode => '0444',
				source => "puppet:///private/svn/svn-authz";
			"/etc/viewvc/viewvc.conf":
				owner => 'root',
				group => 'root',
				mode => '0444',
				source => "puppet:///files/svn/viewvc.conf";
			"/etc/viewvc/templates/revision.ezt":
				owner => 'root',
				group => 'root',
				mode => '0444',
				source => "puppet:///files/svn/revision.ezt";
		}
	}

	class dumps {
		require "svn::server"

		file {
			"/svnroot/bak":
				ensure => directory,
				owner => 'root',
				group => 'svnadm',
				mode => '0775',
				require => File["/svnroot"];
			"/usr/local/bin/svndump.php":
				owner => 'root',
				group => 'root',
				mode => '0555',
				source => "puppet:///files/svn/svndump.php",
				require => File["/svnroot/bak"];
			}

		cron {
			'svndump':
				command => "/usr/local/bin/svndump.php > /dev/null 2>&1",
				require => File["/usr/local/bin/svndump.php"],
				user => root,
				hour => 18,
				minute => 0;
		}
	}

	class hooks {
		# The commit hooks run PHP5
		package { "php5-cli":
			ensure => latest;
		}
	}

	class conversion {
		package { ['libqt4-dev', 'libsvn-dev', 'g++']:
			ensure => latest;
		}
	}

	include viewvc, hooks, dumps, conversion
}

class svn::groups {
	class svn {
		group { "svn":
			name => "svn",
			gid => 550,
			alias => 550,
			ensure => present,
			allowdupe => false;
		}
	}
}

class svn::client {
	package { 'subversion':
		ensure => latest;
	}
}
