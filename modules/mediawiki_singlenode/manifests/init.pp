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
#
#  Memcached memory usage defaults to 128 megs but can be changed via $memcached_size.
class mediawiki_singlenode( $ensure = 'present',
                             $database_name = "testwiki",
                             $wiki_name = "testwiki",
                             $role_requires = [],
                             $install_path = "/srv/mediawiki",
                             $role_config_lines = [],
                             $memcached_size = 128) {
        require "role::labs-mysql-server",
		"webserver::php5-mysql",
		"webserver::php5"

	package { [ "imagemagick", "php-apc",  ] :
		ensure => latest
	}

	class { "memcached":
		memcached_ip => "127.0.0.1",
		memcached_size => $memcached_size }

	git::clone { "mediawiki":
		directory => $install_path,
		branch => "master",
		timeout => 1800,
		ensure => $ensure,
		origin => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git";
	}

# get the extensions
	mw-extension { [ "Nuke", "SpamBlacklist", "ConfirmEdit" ]:
		require => Git::Clone["mediawiki"],
		ensure => $ensure,
		install_path => $install_path;
	}

	file {
		"/etc/apache2/sites-available/wiki":
			mode => 644,
			owner => root,
			group => root,
			content => template('mediawiki_singlenode/simplewiki.wmflabs.org'),
			ensure => present;
	}

	file { "/var/www/srv":
		ensure => 'directory';
	}

	file { "/var/www/${install_path}":
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
		command => "/usr/bin/php ${install_path}/maintenance/install.php $wiki_name admin --dbname $database_name --dbuser root --passfile \"${install_path}/orig/adminpass\" --server $mwserver --scriptpath \"${install_path}\" --confpath \"${install_path}/orig/\"",
		logoutput => "on_failure",
	}

	file { "${install_path}/robots.txt":
		require => Git::Clone["mediawiki"],
		ensure => present,
		source => "puppet:///modules/mediawiki_singlenode/robots.txt",
	}

	file { "${install_path}/privacy-policy.xml":
		require => Git::Clone["mediawiki"],
		ensure => present,
		source => "puppet:///modules/mediawiki_singlenode/privacy-policy.xml",
	}

	exec { "import_privacy_policy":
		require => [Exec["mediawiki_setup"], File["${install_path}/privacy-policy.xml"]],
		cwd => "$install_path",
		command => "/usr/bin/php maintenance/importDump.php privacy-policy.xml",
		logoutput => "on_failure",
	}

	if $ensure == 'latest' {
		exec { 'mediawiki_update':
			require => [git::clone["mediawiki"],
				Mw-extension["Nuke"],
				Mw-extension["SpamBlacklist"],
				Mw-extension["ConfirmEdit"],
				File["${install_path}/LocalSettings.php"]],
			command => "/usr/bin/php ${install_path}/maintenance/update.php --quick --conf \"${install_path}/LocalSettings.php\"",
			logoutput => "on_failure",
		}
	}

	apache_site { controller: name => "wiki" }

	exec { 'apache_restart':
		require => [Apache_site['controller']],
		command => "/usr/sbin/service apache2 restart"
	}

	file { "${install_path}/LocalSettings.php":
		require => Exec["mediawiki_setup"],
		content => template('mediawiki_singlenode/labs-localsettings'),
		ensure => present,
	}
}
