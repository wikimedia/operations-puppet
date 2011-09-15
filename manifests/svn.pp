class svn::server {
	system_role { "svn::server": description => "Wikimedia public SVN server" }

	include svn::users::mwdocs
	include svn::groups::svn
	include apaches::packages

	package { [ 'libsvn-notify-perl', 'python-subversion', 'doxygen', 'apache2',
			'libapache2-svn', 'python-pygments', 'viewvc', 'graphviz' ]:
		ensure => latest;
	}
 
	service { apache2:
		require => Package[apache2],
		subscribe => File["/etc/apache2/sites-available/svn"],
		ensure => running;
	}

	file {
		"/usr/local/bin/sillyshell":
			owner => root,
			group => root,
			mode  => 755,
			source => "puppet:///files/svn/sillyshell";
		"/usr/local/bin/ciabot_svn.py":
			owner => root,
			group => root,
			mode  => 755,
			source => "puppet:///files/svn/ciabot_svn.py";
		"/var/log/mwdocs.log":
			owner => mwdocs,
			group => svn,
			mode => 644,
			ensure => present,
			require => Unixaccount[mwdocs];
		"/etc/apache2/sites-available/svn":
			owner => root,
			group => root,
			mode => 644,
			source => "puppet:///files/svn/svn.http-include";
		"/etc/apache2/sites-enabled/000-svn":
			ensure => link,
			target => "/etc/apache2/sites-available/svn";
		"/etc/apache2/sites-enabled/000-default":
			ensure => absent;
		"/etc/apache2/svn-authz":
			owner => root,
			group => root,
			mode => 644,
			source => "puppet:///private/svn/svn-authz";
		"/etc/viewvc/viewvc.conf":
			owner => root,
			group => root,
			mode => 644,
			source => "puppet:///files/svn/viewvc.conf";
		"/var/mwdocs":
			owner => mwdocs,
			group => svn,
			mode => 755,
			ensure => directory,
			require => Unixaccount[mwdocs];
		"/home/mwdocs/phase3":
			ensure => link,
			target => "/var/mwdocs/phase3";
		"/var/cache/svnusers":
			ensure => directory,
			owner => www-data,
			group => www-data,
			mode => 755,
			require => Package[apache2];
		"/svnroot":
			ensure => directory,
			owner => root,
			group => svn,
			mode => 775;
		"/svnroot/bak":
			ensure => directory,
			owner => root,
			group => svnadm,
			mode => 775,
			require => File["/svnroot"];
		"/usr/local/bin/svndump.php":
			owner => root,
			group => root,
			mode => 755,
			source => "puppet:///files/svn/svndump.php",
			require => File["/svnroot/bak"];
	}

	cron {
		doc_generation:
			command => "(cd /home/mwdocs/phase3 && svn up && php maintenance/mwdocgen.php --all) >> /var/log/mwdocs.log 2>&1",
			require => Unixaccount[mwdocs],
			user => "mwdocs",
			hour => 0,
			minute => 0;
		svnuser_generation:
			command => "(cd /var/cache/svnusers && svn up) > /dev/null 2>&1",
			require => Package[apache2],
			user => "www-data",
			hour => 0,
			minute => 0;
		svndump:
			command => "/usr/local/bin/svndump.php > /dev/null 2>&1",
			require => File["/usr/local/bin/svndump.php"],
			user => root,
			hour => 18,
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

}

class svn::users {

	# used in svn.pp
	class mwdocs inherits baseaccount {
		$username = "mwdocs"
		$realname = "mwdocs"
		$myshell = "/bin/bash"
		$uid = 108
		$gid = 550
 
		unixaccount { $realname: username => $username, uid => $uid, gid => $gid }
	}

}

class svn::groups {

	class svn {
		group { "svn":
			name=> "svn",
			gid => 550,
			alias => 550,
			ensure=> present,
			allowdupe => false,
		}
	}

}

class svn::client {

	package { subversion:
		ensure => latest;
	}

}

# RT 1274 dzahn
class svn::server::notify {

# post-commit hook sending out mails with diffs for the public repo
	package { libsvn-notify-perl:
		ensure => latest;
	}
	file {
		"/svnroot/configuration/hooks/post-commit":
			owner => root,
			group => root,
			mode => 755,
			ensure => present,
			source => "puppet:///files/svn/post-commit-hooks";
	}

# another post-commit hook sending out mails WITHOUT diffs for the private repo
	file {
		"/svnroot/private/hooks/post-commit":
			owner => root,
			group => root,
			mode => 755,
			ensure => present,
			source => "puppet:///files/svn/post-commit-hooks_PRIV";
	}

}
