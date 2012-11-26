# mediawiki.pp

class mediawiki::packages {
	package { [ 'wikimedia-task-appserver', 'php5-redis', 'php5-memcached', 'libmemcached10', 'php5-igbinary' ]:
		ensure => latest;
	}

	# Disable timidity-daemon
	# It's recommended by timidity and there's no simple way to avoid installing it
	service { 'timidity':
		enable => false,
		ensure => stopped;
	}
}

class mediawiki::sync {
	# Include this for syncing mw installation
	# Include apache::apache-trigger-mw-sync to ensure that
	# the sync happens each time just before apache is started
	require mediawiki::packages

	exec { 'mw-sync':
		command => '/usr/bin/sync-common',
		cwd => '/tmp',
		user => root,
		group => root,
		path => '/usr/bin:/usr/sbin',
		refreshonly => true,
		timeout => 600,
		logoutput => on_failure;
	}

}

class mediawiki::refreshlinks {
	# Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

	file { '/home/mwdeploy/refreshLinks':
		ensure => directory,
		owner => mwdeploy,
		group => mwdeploy,
		mode => 0664,
	}

	define refreshlinks::cronjob() {

		$cluster = regsubst($name, '@.*', '\1')
		$monthday = regsubst($name, '.*@', '\1')

		cron { "cron-refreshlinks-${name}":
			command => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${cluster}.dblist --dfn-only > /home/mwdeploy/refreshLinks/${name}.log 2>&1",
			user => mwdeploy,
			hour => 0,
			minute => 0,
			monthday => $monthday,
			ensure => present,
		}
	}

	# add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly) (note: s1 is temp. deactivated)
	refreshlinks::cronjob { ['s2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7']: }
}

class mediawiki::user {
	systemuser { 'mwdeploy': name => 'mwdeploy' }
}

# is installed on pdf servers - https://launchpad.net/ubuntu/+source/mediawiki-math
class mediawiki::math {
	package { 'mediawiki-math':
		ensure => latest;
	}
}


# A one-step class for setting up a single-node MediaWiki install,
#  running from a Git tree.
#
#  Roles can insert additional lines into LocalSettings.php via the
#  $role_requires and $role_config_lines vars.
#
#  Members of $role_requires will be inserted wrapped with 'require_once()'.
#
#  Members of $role_config_lines will get inserted into the file verbatim -- be careful about
#  quoting and escaping!  Note that if you're inserting a bunch of lines you'll be better
#  served by creating an additional template and including that via $role_requires.
class mediawiki::singlenode( $ensure = 'present',
                             $role_requires = [],
                             $install_path = "/srv/mediawiki",
                             $role_config_lines = []) {
        require "role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

	package { [ "imagemagick", "php-apc",  ] :
		ensure => latest
	}

	class { "memcached":
		memcached_ip => "127.0.0.1" }

	git::clone { "mediawiki":
		directory => $install_path,
		branch => "master",
		timeout => 1800,
		depth => 1,
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}

	git::clone { "nuke" :
		require => git::clone["mediawiki"],
		directory => "${install_path}/extensions/Nuke",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Nuke.git";
	}

	git::clone { "SpamBlacklist" :
		require => git::clone["mediawiki"],
		directory => "${install_path}/extensions/SpamBlacklist",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/SpamBlacklist.git";
	}

	git::clone { "ConfirmEdit" :
		require => git::clone["mediawiki"],
		directory => "${install_path}/extensions/ConfirmEdit",
		branch => "master",
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/ConfirmEdit.git";
	}

	file {
		"/etc/apache2/sites-available/wiki":
			mode => 644,
			owner => root,
			group => root,
			content => template('apache/sites/simplewiki.wmflabs.org'),
			ensure => present;
	}

	file { '/var/www/srv':
		ensure => 'directory';
	}

	file { '/var/www/${install_path}':
		require => [File['/var/www/srv'], git::clone['mediawiki']],
		ensure => 'link',
		target => $install_path;
	}

	if $labs_mediawiki_hostname {
		$mwserver = "http://$labs_mediawiki_hostname"
	} else {
		$mwserver = "http://$hostname.pmtpa.wmflabs"
	}

	file { "${install_path}/orig":
		require => git::clone["mediawiki"],
		ensure => 'directory';
	}

        exec { 'password_gen':
		require => [git::clone["mediawiki"],  File["${install_path}/orig"]],
		creates => "${install_path}/orig/adminpass",
		command => "/usr/bin/openssl rand -base64 32 | tr -dc _A-Z-a-z-0-9 > ${install_path}/orig/adminpass"
	}

	exec { 'mediawiki_setup':
		require => [git::clone["mediawiki"],  File["${install_path}/orig"], exec['password_gen']],
		creates => "${install_path}/orig/LocalSettings.php",
		command => "/usr/bin/php ${install_path}/maintenance/install.php testwiki admin --dbname testwiki --dbuser root --passfile \"${install_path}/orig/adminpass\" --server $mwserver --scriptpath \"${install_path}\" --confpath \"${install_path}/orig/\"",
		logoutput => "on_failure",
	}

	if $ensure == 'latest' {
		exec { 'mediawiki_update':
			require => [git::clone["mediawiki"],
				git::clone["nuke"],
				git::clone["SpamBlacklist"],
				git::clone["ConfirmEdit"],
				File["${install_path}/LocalSettings.php"]],
			command => "/usr/bin/php ${install_path}/maintenance/update.php --quick --conf \"${install_path}/LocalSettings.php\"",
			logoutput => "on_failure",
		}
	}

        apache_site { controller: name => "wiki" }
        apache_site { 000_default: name => "000-default", ensure => absent }

	exec { 'apache_restart':
		require => [Apache_site['controller'], Apache_site['000_default']],
		command => "/usr/sbin/service apache2 restart"
	}

	file { "${install_path}/LocalSettings.php":
		require => Exec["mediawiki_setup"],
		content => template('mediawiki/labs-localsettings'),
		ensure => present,
	}
}

class mediawiki::extension-distributor {
	system_role { "mediawiki::extension-distributor": description => "MediaWiki extension distributor" }

	$extdist_working_dir = "/mnt/upload6/private/ExtensionDistributor"
	$extdist_download_dir = "/mnt/upload6/ext-dist"

	package { xinetd:
		ensure => latest;
	}

	systemuser { extdist: name => "extdist", home => "/var/lib/extdist" }

	file {
		"/etc/xinetd.d/svn_invoker":
			require => [ Package[xinetd], Systemuser[extdist] ],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/misc/svn_invoker.xinetd";
		"/etc/logrotate.d/svn-invoker":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/logrotate/svn-invoker";
		"$extdist_working_dir":
			owner => extdist,
			group => wikidev,
			mode => 0775;
	}

	cron { extdist_updateall:
		command => "php /home/wikipedia/common/wmf-config/extdist/cron.php 2>&1 >/dev/null",
		environment => "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
		hour => 3,
		minute => 0,
		user => extdist,
		ensure => present;
	}

	service { xinetd:
		require => [ Package[xinetd], File["/etc/xinetd.d/svn_invoker"] ],
		subscribe => File["/etc/xinetd.d/svn_invoker"],
		ensure => running;
	}
}

class mediawiki::udpprofile::collector {
	system_role { "mediawiki::udpprofile::collector": description => "MediaWiki UDP profile collector" }

	package { "udpprofile":
		ensure => latest;
	}

	service { udpprofile:
		require => Package[ 'udpprofile' ],
		ensure => running;
	}

	# Nagios monitoring (RT-2367)
	monitor_service { "carbon-cache": description => "carbon-cache.py", check_command => "nrpe_check_carbon_cache" }
	monitor_service { "profiler-to-carbon": description => "profiler-to-carbon", check_command => "nrpe_check_profiler_to_carbon" }
	monitor_service { "profiling collector": description => "profiling collector", check_command => "nrpe_check_profiling_collector" }

}
