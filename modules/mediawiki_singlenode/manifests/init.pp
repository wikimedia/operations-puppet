#  A one-step class for setting up a single-node MediaWiki install,
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
class mediawiki_singlenode(
	$ensure            = 'present',
	$database_name     = 'testwiki',
	$wiki_name         = 'testwiki',
	$role_requires     = [],
	$install_path      = '/srv/mediawiki',
	$role_config_lines = [],
	$mysql_pass = '',
	$memcached_size    = 128
) {
	if !defined(Class['webserver::php5']) {
		class {'webserver::php5':
			ssl => true;
		}
	}
	require role::labs-mysql-server, webserver::php5-mysql

	package { [ 'imagemagick', 'php-apc' ] :
		ensure => latest,
	}

    if !defined(Class['memcached']) {
		class { 'memcached':
			memcached_ip   => '127.0.0.1',
			memcached_size => $memcached_size,
		}
	}

	git::clone { 'mediawiki':
		ensure    => $ensure,
		directory => $install_path,
		branch    => 'master',
		timeout   => 1800,
		origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git',
	}

	mw-extension { [ 'Nuke', 'SpamBlacklist', 'ConfirmEdit' ]:
		ensure       => $ensure,
		install_path => $install_path,
	}

	file { '/etc/apache2/sites-available/wiki':
		ensure  => present,
		owner   => root,
		group   => root,
		mode    => '0644',
		content => template('mediawiki_singlenode/mediawiki_singlenode.erb'),
	}

	if $::labs_mediawiki_hostname {
		$mwserver = "http://${::labs_mediawiki_hostname}"
	} else {
		$mwserver = "http://${::hostname}.pmtpa.wmflabs"
	}

	file { "${install_path}/orig":
		ensure  => directory,
		require => Git::Clone['mediawiki'],
	}

	exec { 'password_gen':
		require => [ Git::Clone['mediawiki'],  File["${install_path}/orig"] ],
		creates => "${install_path}/orig/adminpass",
		command => "/usr/bin/openssl rand -base64 32 | tr -dc _A-Z-a-z-0-9 > ${install_path}/orig/adminpass"
	}

	exec { 'mediawiki_setup':
		require   => [ Git::Clone['mediawiki'],  File["${install_path}/orig"], exec['password_gen'] ],
		creates   => "${install_path}/orig/LocalSettings.php",
		command   => "/usr/bin/php ${install_path}/maintenance/install.php ${wiki_name} admin --dbname ${database_name} --dbuser root --passfile \"${install_path}/orig/adminpass\" --server ${mwserver} --installdbuser=\"root\" --installdbpass \"${mysql_pass}\" --scriptpath \"${install_path}\" --confpath \"${install_path}/orig/\"",
		logoutput => on_failure,
	}

	file { "${install_path}/robots.txt":
		ensure  => present,
		require => Git::Clone['mediawiki'],
		source  => 'puppet:///modules/mediawiki_singlenode/robots.txt',
	}

	file { "${install_path}/skins/common/images/labs_mediawiki_logo.png":
		ensure  => present,
		require => Git::Clone['mediawiki'],
		source  => 'puppet:///modules/mediawiki_singlenode/labs_mediawiki_logo.png',
	}

	file { "${install_path}/privacy-policy.xml":
		ensure  => present,
		require => Git::Clone['mediawiki'],
		source  => 'puppet:///modules/mediawiki_singlenode/privacy-policy.xml',
	}

	exec { 'import_privacy_policy':
		require   => [ Exec['mediawiki_setup'], File["${install_path}/privacy-policy.xml"] ],
		cwd       => $install_path,
		command   => '/usr/bin/php maintenance/importDump.php privacy-policy.xml',
		logoutput => on_failure,
	}

	if $ensure == 'latest' {
		exec { 'mediawiki_update':
			require   => [
				Git::Clone['mediawiki'],
				Mw-extension['Nuke'],
				Mw-extension['SpamBlacklist'],
				Mw-extension['ConfirmEdit'],
				File["${install_path}/LocalSettings.php"]
			],
			command   => "/usr/bin/php ${install_path}/maintenance/update.php --quick --conf \"${install_path}/LocalSettings.php\"",
			logoutput => on_failure,
		}
	}

	apache_site { 'wikicontroller':
		name   => 'wiki',
		notify => Exec['apache_restart'],
	}

	apache_module { 'rewrite':
		name   => 'rewrite',
		notify => Exec['apache_restart'],
	}

	exec { 'apache_restart':
		command     => '/usr/sbin/service apache2 restart',
		refreshonly => true,
	}

	file { "${install_path}/cache":
		require => Exec['mediawiki_setup'],
		mode    => '0775',
		owner   => 'www-data',
	}

	file { "${install_path}/images":
		require => Exec['mediawiki_setup'],
		mode    => '0775',
		owner   => 'www-data',
	}

	file { "${install_path}/LocalSettings.php":
		ensure  => present,
		require => Exec['mediawiki_setup'],
		content => template('mediawiki_singlenode/labs-localsettings'),
	}
}
