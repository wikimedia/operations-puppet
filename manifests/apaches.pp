# apaches.pp

class apaches::packages {
	# wikimedia-task-appserver moved to mediawiki.pp

	package { [ "libapache2-mod-php5", "php5-cli", "php-pear", "php5-common",
			"php5-curl", "php5-mysql", "php5-xmlrpc", "php5", "php-wikidiff2",
			"php5-wmerrors", "php5-intl", "php-luasandbox",
			"php-mail", "php-mail-mime" ]:
		ensure => latest;
	}

	if ($::lsbdistcodename == "precise") {
		# On Precise, the 'php5' packages also provides the 'php5-fpm' which
		# install an unneeded fast CGI server.
		package { [ "php5-fpm" ]:
			ensure => absent;
		}
	}
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
		# TODO: use class geoip for this instead of manually downloading.
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

	# FIXME: dirty temp hack
	if $cluster == "api_appserver" {
		$apache_conf = "puppet:///files/apache/apache2.conf.api_appserver"
	}
	else {
		$apache_conf = "puppet:///files/apache/apache2.conf.appserver"
	}

	file {
		"/etc/apache2/apache2.conf":
			owner => root,
			group => root,
			mode => 0444,
			source => $apache_conf;
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
		"/etc/php5/conf.d/igbinary.ini":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/php/igbinary.ini";
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
}

class apaches::service {
	include mediawiki::sync

	if( $::realm == 'labs' ) {
		include nfs::apache::labs
	}

	# Require apaches::files to be in place
	require apaches::files

	include sudo::appserver

	# Adjust nice levels
	require apaches::nice

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

class apaches::monitoring( $realm='production' ) {
	monitor_service { "appserver http": description => "Apache HTTP",
		check_command => $realm ? { 'production' => "check_http_wikipedia",
				'labs' => "check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page" }
	}
}

class apaches::ganglia {
	file {
		"/usr/lib/ganglia/python_modules/apache_status.py":
			source => "puppet:///files/ganglia/plugins/apache_status.py",
			notify => Service[gmond];
		"/etc/ganglia/conf.d/apache_status.pyconf":
			source => "puppet:///files/ganglia/plugins/apache_status.pyconf",
			notify => Service[gmond];
	}
}

## this should be removed. can now use above.
class apaches::monitoring::labs {
	class { "apaches::monitoring": realm => 'labs' }
}


class apaches::fonts {
	package { [ "texlive-fonts-recommended" ]:
		ensure => latest;
	}
}

class apaches::syslog {
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

class apaches::nice {
	# Adjust sshd nice level per RT #664.
	#
	# Has to be less than apache, and apache has to be nice 0 or less to be
	# blue in ganglia.
	#
	# Upstart requires that the job be stopped and started, not just restarted,
	# since restarting will use the old configuration.
	#
	# In precise this can be replaced with creation of /etc/init/ssh.override
	exec {
		"adjust ssh nice":
			path => "/usr/sbin:/usr/bin:/sbin:/bin",
			unless => "grep -q ^nice /etc/init/ssh.conf",
			command => "echo 'nice -10' >> /etc/init/ssh.conf && (stop ssh ; start ssh)";
	}
}
