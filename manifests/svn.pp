class svn::server {
	system_role { "svn::server": description => "public SVN server" }

	# TODO: split up class into multiple sub classes for e.g. pure SVN server,
	# viewvc, backups, etc.

	require "svn::users::mwdocs"
	require "svn::groups::svn"
	
	include generic::webserver::php5

	package { [ 'libsvn-notify-perl', 'python-subversion', 'doxygen',
			'libapache2-svn', 'python-pygments', 'viewvc', 'graphviz' ]:
		ensure => latest;
	}

	file {
		"/usr/local/bin/sillyshell":
			owner => root,
			group => root,
			mode  => 0555,
			source => "puppet:///files/svn/sillyshell";
		"/usr/local/bin/ciabot_svn.py":
			owner => root,
			group => root,
			mode  => 0555,
			source => "puppet:///files/svn/ciabot_svn.py";
		"/var/log/mwdocs.log":
			owner => mwdocs,
			group => svn,
			mode => 0644,
			ensure => present;
		"/etc/apache2/sites-available/svn":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/svn/svn.http-include",
			notify => Service[apache2];
		"/etc/apache2/sites-enabled/000-default":
			ensure => absent;
		"/etc/apache2/svn-authz":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///private/svn/svn-authz";
		"/etc/viewvc/viewvc.conf":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/svn/viewvc.conf";
		"/var/mwdocs":
			owner => mwdocs,
			group => svn,
			mode => 0755,
			ensure => directory;
		"/home/mwdocs/phase3":
			ensure => link,
			target => "/var/mwdocs/phase3";
		"/var/cache/svnusers":
			ensure => directory,
			owner => www-data,
			group => www-data,
			mode => 0755,
			require => Package[apache2];
		"/svnroot":
			ensure => directory,
			owner => root,
			group => svn,
			mode => 0775;
	}
	
	apache_site { "svn": name => "svn", prefix => "000-" }

	cron {
		doc_generation:
			command => "(cd /home/mwdocs/phase3 && svn up && php maintenance/mwdocgen.php --all) >> /var/log/mwdocs.log 2>&1",
			user => "mwdocs",
			hour => 0,
			minute => 0;
		svnuser_generation:
			command => "(cd /var/cache/svnusers && svn up) > /dev/null 2>&1",
			require => Package[apache2],
			user => "www-data",
			hour => 0,
			minute => 0;
	}

	exec { "/usr/bin/svn co file:///svnroot/mediawiki/trunk/phase3":
		creates => "/var/mwdocs/phase3",
		cwd => "/var/mwdocs",
		user => "mwdocs",
		require => File["/var/mwdocs"];
	}

	exec { "/usr/bin/svn co file:///svnroot/mediawiki/USERINFO svnusers":
		creates => "/var/cache/svnusers/.svn",
		cwd => "/var/cache",
		user => "www-data",
		require => File["/var/cache/svnusers"];
	}
	
	class dumps {
		require "svn::server"
		
		file {
			"/svnroot/bak":
				ensure => directory,
				owner => root,
				group => svnadm,
				mode => 0775,
				require => File["/svnroot"];
			"/usr/local/bin/svndump.php":
				owner => root,
				group => root,
				mode => 0555,
				source => "puppet:///files/svn/svndump.php",
				require => File["/svnroot/bak"];
			}
		
		cron {
			svndump:
				command => "/usr/local/bin/svndump.php > /dev/null 2>&1",
				require => File["/usr/local/bin/svndump.php"],
				user => root,
				hour => 18,
				minute => 0;
		}
	}

	include dumps
}

class svn::users {
	class mwdocs {
		user { "mwdocs":
			name => "mwdocs",
			uid => 108,
			gid => 550,
			comment => "mwdocs",
			shell => "/bin/bash",
			ensure => "present",
			managehome => true,
			allowdupe => false,
			require => Group[550],
		}
	}
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

	package { subversion:
		ensure => latest;
	}

}
