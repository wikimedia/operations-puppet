# apaches.pp

# Virtual monitor group resources for the monitoring server
@monitor_group { "appserver": description => "pmtpa application servers" }
@monitor_group { "api_appserver": description => "pmtpa API application servers" }
@monitor_group { "bits_appserver": description => "pmtpa Bits application servers" }

class apaches::packages {
	# wikimedia-task-appserver moved to mediawiki.pp

	package { [ "libapache2-mod-php5", "php5-cli", "php-pear", "php5-common", "php5-curl", "php5-mysql", "php5-xmlrpc" ]:
		ensure => latest;
	}
	if ( $lsbdistcodename == "hardy" ) {
		package { [ "php5-wikidiff2", "php5-wmerrors" ]:
			ensure => latest;
		}
	}
	if ( $lsbdistcodename == "lucid" ) {
		package { [ "php5", "php-wikidiff2", "php5-wmerrors", "php5-intl" ]:
			ensure => latest;
		}
	}
	
	# Explicitly require the Wikimedia version of some packages
	generic::apt::pin-package{ [ "php-wikidiff2" ]: pin => "release o=Wikimedia" }
}

class apaches::cron {
        cron {
		synclocalisation:
			ensure => absent;
		cleanupipc:
			command => "ipcs -s | grep apache | cut -f 2 -d \\  | xargs -rn 1 ipcrm -s",
			user => root,
			minute => 26,
			ensure => present;
		updategeoipdb:
			environment => "http_proxy=http://brewster.wikimedia.org:8080",
			command => "[ -d /usr/share/GeoIP ] && wget -qO - http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /usr/share/GeoIP/GeoIP.dat.new && mv /usr/share/GeoIP/GeoIP.dat.new /usr/share/GeoIP/GeoIP.dat",
			user => root,
			minute => 26,
			ensure => absent;
		cleantmpphp:
			command => "find /tmp -name 'php*' -type f -ctime +1 -exec rm -f {} \\;",
			user => root,
			hour => 5,
			minute => 0,
			ensure => present;
	}
}

class apaches::files {
	$file_mail_ini = "
// Force the envelope sender address to empty, since we don't want to receive bounces
mail.force_extra_parameters=\"-f <>\"
"

	$file_wikidiff2_ini = "
; This file is managed by Puppet!
extension=wikidiff2.so
"
	
	require apaches::packages

	file {
		"/etc/apache2/apache2.conf":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/apache/apache2.conf.appserver";
		"/etc/apache2/envvars":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/apache/envvars.appserver";
		"/etc/php5/apache2/php.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/php/php.ini.appserver";
		"/etc/php5/cli/php.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/php/php.ini.cli.appserver";
		"/etc/php5/conf.d/fss.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/php/fss.ini.appserver";
		"/etc/php5/conf.d/apc.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/php/apc.ini";
		"/etc/php5/conf.d/wmerrors.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/php/wmerrors.ini";
		"/etc/sudoers":
			owner => root,
			group => root,
			mode => 0440,
			source => "puppet:///files/sudo/sudoers.appserver";
		"/etc/php5/conf.d/mail.ini":
			mode => 0444,
			owner => root,
			group => root,
			content => $file_mail_ini;
		"/etc/php5/conf.d/wikidiff2.ini":
			mode => 0444,
			owner => root,
			group => root,
			content => $file_wikidiff2_ini;
		"/etc/cluster":
			mode => 0444,
			owner => root, 
			group => root, 
			content => $site;
	}

	# local run of sync-apache for initial deploy
	exec { 
		'local_sync_apache':
			unless => '/usr/bin/test -d "/usr/local/apache/conf" ',
			command => "/usr/bin/rsync -av 10.0.5.8::httpdconf/ /usr/local/apache/conf";
		'local_sync_common':
			subscribe => Exec['local_sync_apache'],
			refreshonly => true,
			command => "/usr/bin/sync-common";
		'apache_graceful':
			subscribe => Exec['local_sync_common'],
			refreshonly => true,
			command => "/usr/sbin/apache2ctl graceful";
	}	
}

class apaches::service {
	include mediawiki::sync

	# Require apaches::files to be in place
	require apaches::files

        # Sync the server when we see apache is not running 
	exec { 'apache-trigger-mw-sync':
		command => '/bin/true',
		notify => Exec['mw-sync'],
		unless => "/bin/ps -C apache2 > /dev/null"
	}

	# Start apache but not at boot
	service { 'apache':
		name => "apache2",
		enable => false,
		ensure => running;
	}

	# trigger sync, then start apache (if not running)
	Exec['apache-trigger-mw-sync'] -> Service['apache']
}

class apaches::pybal-check {
	$authorized_key = 'command="uptime; touch /var/tmp/pybal-check.stamp" ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwyiL/ImTNOjoP/8k1UFQRM9pcspHp3yIsH/8TYXH/HJ1rQVjMleq6IQ6ZwAXhKfw/v1xV28SbkctB8pISZoR4rcCqOIN+osXkCB419JydCEb5abPS4mB5Gkn2bZAF43DGr5kaW+HYIsgtZ+QEC+nS4j3NA/Bjb7lAbHUtHVuC6BCOaZfGf+Q2FO4Z6xC7zc/1ngaDgvrXYzyCvXzTAQmcZH0d2/GoS1DQoLdLzqu66aZK1dmn9TAHV4a3R4gp7El7OzVHqDp1E6y0sopd+qKNAw/3GgXC91XJ3XO22h+ZnVovIpIS01CJ6GiBig/55Xrh//9Wuw5GFQuCptYbPQr4Q== root@lvs4'

	# Create pybal-check user account	
	systemuser { "pybal-check": name => "pybal-check", home => "/var/lib/pybal-check", shell => "/bin/sh" }

	file {
		"/var/lib/pybal-check/.ssh":
			require => Systemuser["pybal-check"],
			owner => pybal-check,
			group => pybal-check,
			mode => 0750,
			ensure => directory;
		"/var/lib/pybal-check/.ssh/authorized_keys":
			require => File["/var/lib/pybal-check/.ssh"],
			owner => pybal-check,
			group => pybal-check,
			mode => 0640,
			content => $authorized_key;
	}
}

class apaches::monitoring {
	monitor_service { "appserver http": description => "Apache HTTP", check_command => "check_http_wikipedia" }
}

class apaches::fonts {
	package { [ "texlive-fonts-recommended" ]:
		ensure => latest;
	}
}
