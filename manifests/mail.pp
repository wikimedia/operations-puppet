# mail.pp

class exim {
	class constants {
		$primary_mx = [ "208.80.152.186", "2620::860:2:219:b9ff:fedd:c027" ]
	}

	class config($install_type="light", $queuerunner="queueonly") {
		package { [ "exim4-config", "exim4-daemon-${install_type}" ]: ensure => latest }

		if $install_type == "heavy" {
			exec { "mkdir /var/spool/exim4/scan":
				require => Package[exim4-daemon-heavy],
				path => "/bin:/usr/bin",
				creates => "/var/spool/exim4/scan"
			}

			mount { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
				device => "none",
				fstype => "tmpfs",
				options => "defaults",
				ensure => mounted
			}

			file { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
				ensure => directory,
				owner => Debian-exim,
				group => Debian-exim
			}

			# add nagios to the Debian-exim group to allow check_disk tmpfs mounts (puppet still can't manage existing users?! so just Exec)
			exec { "nagios_to_exim_group":
				command => "usermod -a -G Debian-exim nagios",
				path => "/usr/sbin";
			}

			Exec["mkdir /var/spool/exim4/scan"] -> Mount["/var/spool/exim4/scan"] -> File["/var/spool/exim4/scan"]
			Package[exim4-daemon-heavy] -> Mount["/var/spool/exim4/db"] -> File["/var/spool/exim4/db"]
		}

		file {
			"/etc/default/exim4":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				content => template("exim/exim4.default.erb");
			"/etc/exim4/aliases/":
				require => Package[exim4-config],
				mode => 0755,
				owner => root,
				group => root,
				ensure => directory;
		}
	}

	class service {
		Class["exim::config"] -> Class[exim::service]

		# The init script's status command exit value only reflects the SMTP service
		service { exim4:
			ensure => running,
			hasstatus => $exim::config::queuerunner ? {
				"queueonly" => false,
				default => true
			}
		}

		if $exim::config::queuerunner != "queueonly" {
			# Nagios monitoring
			monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
		}
	}

	class simple-mail-sender {
		class { "exim::config": queuerunner => "queueonly" }
		Class["exim::config"] -> Class[exim::simple-mail-sender]

		file {
			"/etc/exim4/exim4.conf":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				content => template("exim/exim4.minimal.erb");
		}

		include exim::service
	}

	class rt {
		class { exim::roled:
         		local_domains => [ "+system_domains", "+rt_domains" ],
         		enable_mail_relay => "false",
			enable_external_mail => "true",
			smart_route_list => [ "mchenry.wikimedia.org", "lists.wikimedia.org" ],
         		enable_mailman => "false",
         		rt_relay => "true",
         		enable_mail_submission => "false",
         		enable_spamassassin => "false"
 		}
	}

	class smtp {
		include passwords::exim
		$otrs_mysql_password = $passwords::exim::otrs_mysql_password
		$smtp_ldap_password = $passwords::exim::smtp_ldap_password
	}

	# Class: exim::roled
	#
	# This class installs a full featured Exim MTA
	#
	# Parameters:
	#	- $local_domains:
	#		List of domains Exim will treat as "local", i.e. be responsible
	#		for
	#	- $enable_mail_relay:
	#		Values: primary, secondary
	#		Whether Exim will act as a primary or secondary mail relay for
	#		other mail servers
	#	- $enable_mailman:
	#		Whether Mailman delivery functionality is enabled (true/false)
	#	- $enable_imap_delivery:
	#		Whether IMAP local delivery functional is enabled (true/false)
	#	- $enable_mail_submission:
	#		Enable/disable mail submission by users/client MUAs
	#	- $mediawiki_relay:
	#		Whether this MTA relays mail for MediaWiki (true/false)
	#	- $enable_spamasssin:
	#		Enable/disable SpamAssassin spam checking
	#	- $outbound_ips:
	#		IP addresses to use for sending outbound e-mail
	#	- $list_outbound_ips:
	#		IP addresses to use for sending outbound e-mail from Mailman
	#	- $hold_domains:
	#		List of domains to hold on the queue without processing
	class roled(
			$enable_clamav="false",
			$enable_external_mail="false",
			$enable_imap_delivery="false",
			$enable_mail_relay="false",
			$enable_mail_submission="false",
			$enable_mailman="false",
			$enable_otrs_server="false",
			$enable_spamassassin="false",
			$hold_domains=[],
			$list_outbound_ips=[],
			$local_domains = [ "+system_domains" ],
			$mediawiki_relay="false",
			$outbound_ips=[ $ipaddress ],
			$rt_relay="false",
			$smart_route_list=[]
		 ) {

		class { "exim::config": install_type => "heavy", queuerunner => "combined" }
		Class["exim::config"] -> Class[exim::roled]

		include exim::service

		include exim::smtp
		include exim::constants
		include network::constants
		include privateexim::listserve

		file {
			"/etc/exim4/exim4.conf":
				require => Package[exim4-config],
				notify => Service[exim4],
				owner => root,
				group => Debian-exim,
				mode => 0440,
				content => template("exim/exim4.conf.SMTP_IMAP_MM.erb");
			"/etc/exim4/dkim/":
				ensure => 'directory',
				purge => true,
				owner => root,
				group => Debian-exim,
				mode => 0440,
				require => Package[exim4-config];
			"/etc/exim4/system_filter":
				owner => root,
				group => Debian-exim,
				mode => 0444,
				content => template("exim/system_filter.conf.erb");
			"/etc/exim4/defer_domains":
				owner => root,
				group => Debian-exim,
				mode => 0444,
				ensure => present;
			"/usr/local/bin/collect_exim_stats_via_gmetric":
				owner => root,
				group => Debian-exim,
				mode => 0755,
				source => 'puppet:///files/ganglia/collect_exim_stats_via_gmetric';
		}

		include backup::host
		backup::set { 'var-vmail': }
		if $enable_mailman {
			backup::set { 'var-lib-mailman': }
		}

		class mail_relay {
			Class["exim::config"] -> Class[exim::roled::mail_relay]

			file { '/etc/exim4/relay_domains':
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/exim/exim4.secondary_relay_domains.conf";
			}
			file { '/etc/exim4/dkim/wikimedia.org-wikimedia.key':
				ensure  => present,
				owner   => 'root',
				group   => 'Debian-exim',
				mode    => '0440',
				source  => 'puppet:///private/dkim/wikimedia.org-wikimedia.key',
				require => File['/etc/exim4/dkim'],
				notify  => Service['exim4'],
			}
		}

		class mailman {
			Class["exim::config"] -> Class[exim::roled::mailman]

			file { '/etc/exim4/aliases/lists.wikimedia.org':
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/exim/exim4.listserver_aliases.conf";
			}
			file { '/etc/exim4/dkim/lists.wikimedia.org-wikimedia.key':
				ensure  => present,
				owner   => 'root',
				group   => 'Debian-exim',
				mode    => '0440',
				source  => 'puppet:///private/dkim/lists.wikimedia.org-wikimedia.key',
				require => File['/etc/exim4/dkim'],
				notify  => Service['exim4'],
			}
		}

		if ( $mediawiki_relay == "true" ) {
			file { '/etc/exim4/dkim/wikimedia.org-wiki-mail.key':
				ensure  => present,
				owner   => 'root',
				group   => 'Debian-exim',
				mode    => '0440',
				source  => 'puppet:///private/dkim/wikimedia.org-wiki-mail.key',
				require => File['/etc/exim4/dkim'],
				notify  => Service['exim4'],
			}
		}

		cron { 'collect_exim_stats_via_gmetric':
			user => 'root',
			command => '/usr/local/bin/collect_exim_stats_via_gmetric',
			ensure => present;
		}

		if ( $enable_mailman == "true" ) {
			include mailman
		}
		if ( $enable_mail_relay == "primary" ) or ( $enable_mail_relay == "secondary" ) {
			include mail_relay
		}
		if ( $enable_spamassassin == "true" ) {
			Class[spamassassin] -> Class[exim::roled]
		}
		if ( $enable_clamav == "true" ) {
			include clamav
		}
	}
}

# https://help.ubuntu.com/community/EximClamAV
# /usr/share/doc/clamav-base/README.Debian.gz
class clamav {

	generic::systemuser { "clamav":
		name => "clamav",
		groups => "Debian-exim", # needed for exim integration
	}

	package { [ "clamav-daemon" ]:
		ensure => latest;
		# note: freshclam needs an initial manual run to fetch virus definitions
		# this takes several minutes to run
	}

	file {
		"/etc/clamav/clamd.conf":
			require => Package["clamav-daemon"],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/clamav/clamd.conf";
	}

	service { "clamav-daemon":
		require => [ File["/etc/clamav/clamd.conf"], Package["clamav-daemon"] ],
		subscribe => [ File["/etc/clamav/clamd.conf"] ],
		ensure => running;
	}

}

# SpamAssassin http://spamassassin.apache.org/
class spamassassin(
		$required_score = '5.0',
		$max_children = 8,
		$nicelevel = 10,
		$use_bayes = 1,
		$bayes_auto_learn = 1,
		$short_report_template = 'false',
		$otrs_rule_scores = 'false',
		$spamd_user = 'spamd',
		$spamd_group = 'spamd'
	) {
	include network::constants

	package { [ "spamassassin" ]:
		ensure => latest;
	}

	# this seems broken, especially since /var/spamd is unused
	# and spamd's homedir is created as /var/lib/spamd
	if ( $spamd_user == "spamd" ) {
		generic::systemuser { "spamd": name => "spamd" }
		file { "/var/spamd":
			require => Generic::Systemuser[spamd],
			ensure => directory,
			owner => spamd,
			group => spamd,
			mode => 0700;
		}
	}

	File {
		require => Package[spamassassin],
		owner => root,
		group => root,
		mode => 0444
	}
	file {
		"/etc/spamassassin/local.cf":
			content => template("spamassassin/local.cf");
		"/etc/default/spamassassin":
			content => template("spamassassin/spamassassin.default.erb");
	}

	service { "spamassassin":
		require => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"], Package[spamassassin] ],
		subscribe => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"] ],
		ensure => running;
	}

	nrpe::monitor_service { 'spamd':
		description   => 'spamassassin',
		nrpe_command  => '/usr/lib/nagios/plugins/check_procs -w 1:20 -c 1:40 -a spamd',
	}
}

class mailman {
	class base {
		# lighttpd needs to be installed first, or the mailman package will pull in apache2
		require webserver::static

		package { "mailman": ensure => latest }
	}

	class listserve {
		require mailman::base

		system::role { "mailman::listserve": description => "Mailman listserver" }

		file {
			"/etc/mailman/mm_cfg.py":
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/mailman/mm_cfg.py";
		}

		# Install as many languages as possible
		include generic::locales::international

		generic::debconf::set {
			"mailman/gate_news":
				value => "false",
				notify => Exec["dpkg-reconfigure mailman"];
			"mailman/used_languages":
				value => "ar big5 ca cs da de en es et eu fi fr gb hr hu ia it ja ko lt nl no pl pt pt_BR ro ru sl sr sv tr uk vi zh_CN zh_TW",
				notify => Exec["dpkg-reconfigure mailman"];
			"mailman/default_server_language":
				value => "en",
				notify => Exec["dpkg-reconfigure mailman"];
		}
		exec { "dpkg-reconfigure mailman":
			require => Class["generic::locales::international"],
			before => Service[mailman],
			command => "/usr/sbin/dpkg-reconfigure -fnoninteractive mailman",
			refreshonly => true
		}

		service { mailman:
			ensure => running,
			hasstatus => false,
			pattern => "mailmanctl"
		}

			nrpe::monitor_service { 'procs_mailman':
			description  => 'mailman',
			nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:25 -c 1:35 -a mailman',
			}
	}

	class web-ui {
		include webserver::static

		if ( $realm == "production" ) {
			install_certificate{ "lists.wikimedia.org": ca => "RapidSSL_CA.pem" }
		}

		# htdigest file for private list archives
		file { "/etc/lighttpd/htdigest":
			require => Class["webserver::static"],
			source => "puppet:///private/lighttpd/htdigest",
			owner => root,
			group => www-data,
			mode => 0440;
		}

		# Enable CGI module
		mailman_lighttpd_config { "10-cgi": require => Class["webserver::static"] }

		# Install Mailman specific Lighttpd config file
		mailman_lighttpd_config { "50-mailman":
			require => [ Class["webserver::static"], File["/etc/lighttpd/htdigest"] ],
			install => "true"
		}

		# Add files in /var/www (docroot)
		file { "/var/www":
			source => "puppet:///files/mailman/docroot/",
			owner => root,
			group => root,
			mode => 0444,
			recurse => remote;
		}

		# monitor SSL cert expiry
		if ( $realm == "production" ) {
			monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org" }
		}
	}

	include listserve, web-ui
}


# Enables a certain Lighttpd config
#
# TODO:  ensure => false removes symlink.  ensure => purged removes available file.
define mailman_lighttpd_config($install="false") {
	# Reload lighttpd if the site config file changes.
	# This subscribes to both the real file and the symlink.
	exec { "lighttpd_reload_${title}":
		command     => "/usr/sbin/service service lighttpd reload",
		refreshonly => true,
	}

	if $install == "true" {
		file { "/etc/lighttpd/conf-available/${title}.conf":
			source => "puppet:///files/lighttpd/${title}.conf",
			owner => root,
			group => www-data,
			mode => 0444,
			before => File["/etc/lighttpd/conf-enabled/${title}.conf"],
			notify => Exec["lighttpd_reload_${title}"],
		}
	}

	# Create a symlink to the available config file
	# in the conf-enabled directory.  Notify
	file { "/etc/lighttpd/conf-enabled/${title}.conf":
		ensure => "/etc/lighttpd/conf-available/${title}.conf",
		notify => Exec["lighttpd_reload_${title}"],
	}

}
