# mediawiki.pp

class mediawiki::packages {
	package { [ 'wikimedia-task-appserver', 'php5-redis', 'php5-memcached', 'libmemcached10', 'php5-igbinary' ]:
		ensure => latest;
	}
}

class mediawiki::sync {
	# Include this for syncinc mw installation
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

class mediawiki::updatequerypages {
	# Include this to add cron jobs calling updateSpecialPages.php on all clusters.

	file { '/home/mwdeploy/updateSpecialPages':
		ensure => directory,
		owner => mwdeploy,
		group => mwdeploy,
		mode => 0664,
	}

	define updatequerypages::cronjob() {

		$cluster = regsubst($name, '@.*', '\1')
		$monthday = regsubst($name, '.*@', '\1')

		cron { "cron-updatequerypages-ancientpages-${name}":
			command => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=AncientPages > /home/mwdeploy/updateSpecialPages/${name}-AncientPages.log 2>&1",
			user => mwdeploy,
			hour => 1,
			minute => 0,
			month => [1, 7]
			monthday => $monthday,
			ensure => present,
		}

		cron { "cron-updatequerypages-deadendpages-${name}":
			command => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=DeadendPages > /home/mwdeploy/updateSpecialPages/${name}-DeadendPages.log 2>&1",
			user => mwdeploy,
			hour => 1,
			minute => 0,
			month => [2, 8]
			monthday => $monthday,
			ensure => present,
		}

		cron { "cron-updatequerypages-mostlinked-${name}":
			command => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=MostLinked > /home/mwdeploy/updateSpecialPages/${name}-MostLinked.log 2>&1",
			user => mwdeploy,
			hour => 1,
			minute => 0,
			month => [3, 9]
			monthday => $monthday,
			ensure => present,
		}

		cron { "cron-updatequerypages-mostrevisions-${name}":
			command => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=MostRevisions > /home/mwdeploy/updateSpecialPages/${name}-MostRevisions.log 2>&1",
			user => mwdeploy,
			hour => 1,
			minute => 0,
			month => [4, 10]
			monthday => $monthday,
			ensure => present,
		}

		cron { "cron-updatequerypages-wantedpages-${name}":
			command => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=WantedPages > /home/mwdeploy/updateSpecialPages/${name}-WantedPages.log 2>&1",
			user => mwdeploy,
			hour => 1,
			minute => 0,
			month => [5, 11]
			monthday => $monthday,
			ensure => present,
		}

		cron { "cron-updatequerypages-fewestrevisions-${name}":
			command => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=FewestRevisions > /home/mwdeploy/updateSpecialPages/${name}-FewestRevisions.log 2>&1",
			user => mwdeploy,
			hour => 1,
			minute => 0,
			month => [6, 12]
			monthday => $monthday,
			ensure => present,
		}
	}

	# add cron jobs - usage: <cluster>@<day of month>
	updatequerypages::cronjob { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17']: }
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
class mediawiki::singlenode( $keep_up_to_date = false,
                             $role_requires = [],
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
		directory => "/srv/mediawiki",
		branch => "master",
		timeout => 1800,
		depth => 1,
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}

	git::clone { "nuke" :
		require => git::clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/Nuke",
		branch => "master",
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/Nuke.git";
	}

	git::clone { "SpamBlacklist" :
		require => git::clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/SpamBlacklist",
		branch => "master",
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/extensions/SpamBlacklist.git";
	}

	git::clone { "ConfirmEdit" :
		require => git::clone["mediawiki"],
		directory => "/srv/mediawiki/extensions/ConfirmEdit",
		branch => "master",
		ensure => $keep_up_to_date ? {
			true => latest,
			default => present
		},
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

	file { '/var/www/srv/mediawiki':
		require => [File['/var/www/srv'], git::clone['mediawiki']],
		ensure => 'link',
		target => '/srv/mediawiki';
	}

	if $labs_mediawiki_hostname {
		$mwserver = "http://$labs_mediawiki_hostname"
	} else {
		$mwserver = "http://$hostname.pmtpa.wmflabs"
	}

	file { '/srv/mediawiki/orig':
		require => git::clone["mediawiki"],
		ensure => 'directory';
	}

        exec { 'password_gen':
		require => [git::clone["mediawiki"],  File["/srv/mediawiki/orig"]],
		creates => "/srv/mediawiki/orig/adminpass",
		command => "/usr/bin/openssl rand -base64 32 | tr -dc _A-Z-a-z-0-9 > /srv/mediawiki/orig/adminpass"
	}

	exec { 'mediawiki_setup':
		require => [git::clone["mediawiki"],  File["/srv/mediawiki/orig"], exec['password_gen']],
		creates => "/srv/mediawiki/orig/LocalSettings.php",
		command => "/usr/bin/php /srv/mediawiki/maintenance/install.php testwiki admin --dbname testwiki --dbuser root --passfile '/srv/mediawiki/orig/adminpass' --server $mwserver --scriptpath '/srv/mediawiki' --confpath '/srv/mediawiki/orig/'",
		logoutput => "on_failure",
	}

	if $keep_up_to_date == 'true' {
		exec { 'mediawiki_update':
			require => [git::clone["mediawiki"],
				git::clone["nuke"],
				git::clone["SpamBlacklist"],
				git::clone["ConfirmEdit"],
				File["/srv/mediawiki/LocalSettings.php"]],
			command => "/usr/bin/php /srv/mediawiki/maintenance/update.php --quick --conf '/srv/mediawiki/LocalSettings.php'",
			logoutput => " ",
		}
	}

        apache_site { controller: name => "wiki" }
        apache_site { 000_default: name => "000-default", ensure => absent }

	exec { 'apache_restart':
		require => [Apache_site['controller'], Apache_site['000_default']],
		command => "/usr/sbin/service apache2 restart"
	}

	file { '/srv/mediawiki/LocalSettings.php':
		require => Exec["mediawiki_setup"],
		content => template('mediawiki/labs-localsettings'),
		ensure => present,
	}
}
