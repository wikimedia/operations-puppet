# TODO: break this up in different (sub) classes for the different services
class misc::fundraising {

	include passwords::civi,
		mysql::client::default-charset-binary

	#what is currently on grosley/aluminium
	system_role { 'misc::fundraising': description => 'fundraising sites and operations' }

	require mysql::client

	package { [ 'libapache2-mod-php5', 'php5-cli', 'php-pear', 'php5-common', 'php5-curl', 'php5-dev', 'php5-gd', 'php5-mysql', 'php5-sqlite', 'subversion', 'phpunit', 'python-scipy', 'python-matplotlib', 'python-libxml2', 'python-sqlite', 'python-sqlitecachec', 'python-urlgrabber', 'python-argparse', 'python-dev', 'python-setuptools', 'python-mysqldb', 'libapache2-mod-python', 'r-base', 'r-cran-rmysql', 'python-rpy2' ]:
		ensure => latest;
	}

	file {

		'/etc/logrotate.d/fundraising-civicrm':
			owner => root,
			group => root,
			mode => 0644,
			source => 'puppet:///private/misc/fundraising/logrotate.fundraising-civicrm';

		#civicrm confs
		'/srv/org.wikimedia.civicrm/sites/default/civicrm.settings.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/civicrm.civicrm.settings.php';
		'/srv/org.wikimedia.civicrm/sites/default/default.settings.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/civicrm.default.settings.php';
		'/srv/org.wikimedia.civicrm/sites/default/settings.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/civicrm.settings.php';

		#civicrm dev confs
		'/srv/org.wikimedia.civicrm-dev/sites/default/civicrm.settings.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/dev.civicrm.civicrm.settings.php';
		'/srv/org.wikimedia.civicrm-dev/sites/default/default.settings.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/dev.civicrm.default.settings.php';
		'/srv/org.wikimedia.civicrm-dev/sites/default/settings.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/dev.civicrm.settings.php';

		#misc fundraising confs
		'/opt/fundraising-misc/queue_handling/payflowpro/executeStompPFPPendingProcessorSA.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/misc.executeStompPFPPendingProcessorSA.php';
		'/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Recurring.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/misc.IPNListener_Recurring.php';
		'/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/misc.IPNListener_Standalone.php';
		'/opt/fundraising-misc/auditing/paypal-audit/auth.cfg':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			source => 'puppet:///private/misc/fundraising/fundraising-misc.auth.cfg';
		'/opt/fundraising-misc/public_reporting/update_config.php':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/fundraising-misc.update_config.php';
		'/srv/org.wikimedia.fundraising/IPNListener_Standalone.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			ensure => '/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php';
		'/srv/org.wikimedia.civicrm/fundcore_gateway/paypal':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			ensure => '/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php';
		'/srv/org.wikimedia.civicrm/IPNListener_Recurring.php':
			owner => www-data,
			group => wikidev,
			mode => 0440,
			ensure => '/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Recurring.php';
		'/srv/org.wikimedia.civicrm/files':
			owner => www-data,
			group => wikidev,
			mode => 0775,
			ensure => directory;
		'/srv/org.wikimedia.civicrm-dev/files':
			owner => www-data,
			group => wikidev,
			mode => 0775,
			ensure => directory;
		'/srv/org.wikimedia.civicrm/fundcore_gateway':
			owner => www-data,
			group => wikidev,
			mode => 0775,
			ensure => directory;
		'/srv/org.wikimedia.civicrm/fundcore_gateway/.htaccess':
			owner => www-data,
			group => wikidev,
			mode => 0444,
			content => "<Files paypal>
	ForceType application/x-httpd-php
</Files>";

		#apache conf stuffs
		'/etc/php5/apache2/php.ini':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/php/php.ini.civicrm';
		'/etc/apache2/sites-available/000-donate':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.donate';
		'/etc/apache2/sites-available/001-civicrm':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.civicrm';
		'/etc/apache2/sites-available/002-civicrm-ssl':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.civicrm-ssl';
		'/etc/apache2/sites-available/003-civicrm-dev':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.civicrm-dev';
		'/etc/apache2/sites-available/004-civicrm-dev-ssl':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.civicrm-dev-ssl';
		'/etc/apache2/sites-available/005-fundraising':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.fundraising';
		'/etc/apache2/sites-available/006-fundraising-ssl':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.fundraising-ssl';
		'/etc/apache2/sites-available/007-fundraising-analytics':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.fundraising-analytics';
		'/etc/apache2/sites-available/008-community-analytics':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/misc/fundraising/apache.conf.community-analytics';

		'/usr/local/bin/drush':
			ensure => '/opt/drush/drush';

		# other stuff
		'/etc/php5/cli/php.ini':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///private/php/php.ini.fundraising.cli';
	}

	#enable apache mods
	apache_module { rewrite: name => 'rewrite' }
	apache_module { ssl: name => 'ssl' }

	#enable apache sites
	apache_site { 'donate': name => '000-donate' }
	apache_site { 'civicrm': name => '001-civicrm' }
	apache_site { 'civicrm-ssl': name => '002-civicrm-ssl' }
	apache_site { 'civicrm-dev': name => '003-civicrm-dev' }
	apache_site { 'civicrm-dev-ssl': name => '004-civicrm-dev-ssl' }
	apache_site { 'fundraising': name => '005-fundraising' }
	apache_site { 'fundraising-ssl': name => '006-fundraising-ssl' }
	apache_site { 'fundraising-analytics': name => '007-fundraising-analytics' }
	apache_site { 'community-analytics': name => '008-community-analytics' }

}

class misc::fundraising::backup::dump_fundraising_database(
		$user = 'root',
		$hour,
		$minute,
		$weekday = [0, 1, 2, 3, 4, 5, 6],
	) {

	file { 
		'/usr/local/bin/dump_fundraisingdb':
			owner => root,
			group => root,
			mode => 0755,
			source => 'puppet:///files/misc/scripts/dump_fundraisingdb',
	}

	cron {
		'dump_fundraising_database':
			user => $user,
			weekday => $weekday,
			hour => $minute,
			minute => $hour,
			command => '/usr/local/bin/dump_fundraisingdb',
			ensure => present;
	}

}

class misc::fundraising::backup::archive_sync(
		$user = 'root',
		$hour,
		$minute,
		$weekday = [0, 1, 2, 3, 4, 5, 6],
		$email = 'quiet', # quiet|errors|all
	) {

	if $email == 'quiet' {
		$command = '/usr/local/bin/offhost_backups -q'
	} elsif $email == 'errors' {
		$command = '/usr/local/bin/offhost_backups -e'
	} else {
		$command = '/usr/local/bin/offhost_backups'
	}

	file { 
		'/usr/local/bin/offhost_backups':
			owner => root,
			group => root,
			mode => 0755,
			source => 'puppet:///files/misc/scripts/offhost_backups',
	}

	cron {
		'offhost_backups':
			user => $user,
			weekday => $weekday,
			hour => $minute,
			minute => $hour,
			command => $command,
			ensure => present;
	}

}


class misc::fundraising::mail {

	system_role { 'misc::fundraising::mail': description => 'fundraising mail server' }

	package { [ 'dovecot-imapd', 'exim4-daemon-heavy', 'exim4-config' ]:
		ensure => latest;
	}

	group { civimail:
		ensure => 'present',
	}

	user { civimail:
		name => 'civimail',
		gid => 'civimail',
		groups => [ 'civimail' ],
		membership => 'minimum',
		password => $passwords::civi::civimail_pass,
		home => '/home/civimail',
		shell => '/bin/sh';
	}

	file {
		'/etc/exim4/exim4.conf':
			owner => root,
			group => root,
			mode => 0444,
			content => template('exim/exim4.donate.erb');
		'/etc/exim4/wikimedia.org-fundraising-private.key':
			owner => root,
			group => Debian-exim,
			mode => 0440,
			source => 'puppet:///private/dkim/wikimedia.org-fundraising-private.key';
		'/etc/dovecot/dovecot.conf':
			owner => root,
			group => root,
			mode => 0444,
			source => 'puppet:///files/dovecot/dovecot.donate.conf';
		'/var/mail/civimail':
			owner => 'civimail',
			group => 'civimail',
			mode => 2755,
			ensure => directory;
		'/usr/local/bin/collect_exim_stats_via_gmetric':
			owner => root,
			group => root,
			mode => 0755,
			source => 'puppet:///files/ganglia/collect_exim_stats_via_gmetric';
		'/usr/local/bin/civimail_send':
			owner => root,
			group => wikidev,
			mode => 0710,
			source => 'puppet:///private/misc/fundraising/civimail_send';
		'/etc/amazon-audit.cfg':
			owner => root,
			group => wikidev,
			mode => 0740,
			source => 'puppet:///private/misc/fundraising/amazon-audit.cfg';
	}

	cron {
		'collect_exim_stats_via_gmetric':
			user => root,
			command => '/usr/local/bin/collect_exim_stats_via_gmetric',
			ensure => present;
		'exim_queue_count_for_mailer_script':
			user => root,
			command => '/usr/sbin/exim -bpc > /tmp/exim_queue_count.dat',
			ensure => present;
	}

}


class misc::fundraising::backup::backupmover_user {

	systemuser { backupmover: name => 'backupmover', home => '/var/lib/backupmover', shell => '/bin/sh' }

	ssh_authorized_key {
		'backupmover/root@boron':
			ensure  => present,
			user	=> backupmover,
			type	=> 'ssh-rsa',
			key	 => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDIljE3d12L8SEO1pkiBBJplyBDCR6zRewQ+SpGWC9pe5X/gob92Yx4P0ZELFrpC+fkZlYFh0ebe0sJilBEzpLr/BFwafXZ6RvNBhU8pMSTUkb6DN9c3jG+gSyq6UIECEuF8uqOVk+1uaFg1ve9ODVfgHGiVQISS8YW/W9dFXCi9wo8gkH4L7nxptV2lkGLcjq60OoMDuS4iOzOdeQt5jguOG43XDqgyRN4tvqG54KtIjGUQP6KNpL2kGCA4WNrPnkeiNRLV9+RyLKFDjWOTT7ELk6HifuN2pn46E1DURNL6mlfw1uaoClhMruRijpZKj9wHB4awBWk0/VwPf8rpjFp';
		'backupmover/root@indium':
			ensure  => present,
			user	=> backupmover,
			type	=> 'ssh-rsa',
			key	 => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDOGHFRKrjHeejEiv4tIs/MLt5+BFRquh1HlGs+iRM672xv32RtU/G3vhAWqEmGjXAFgrKB3O6faEXr4c4SJ3Vlxvr6fEsBAB0pe4GW0IJgD0HfiyIqL0m1NDU6molt79hamRmL8kBwCuRUDISbmUJw7MCNYzTd8IiE2/5Asha9QdQS1RuhkcNsaL+9jH4/wU9NND7TXpf1qu8Rd8t7HAVgxRmx0ikkTu3YeuYXdlEIoDfWeBtoStCi50uA91ckdDIsCIXLcfctMX5cRQbTtY2OgxJIWUsgiraac8rAE35gmthSVRrW3HoZGya0Fz5YlN+YLIrUkZHz1Ghx3boZgke1';
		'backupmover/root@aluminium':
			ensure  => present,
			user	=> backupmover,
			type	=> 'ssh-rsa',
			key	 => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAv86yzKoTo6pcgfJVQ51FAIcQ8NwUhWd93SKNRTqDmIkkMOe6lVruEManMOqJXGcVWp8WpCvqzkIyx77Y5HZISzVZL3hEfkJL85HyOn8gWB9jF2uNYa16Ik2nXR/HxP0w/xajJM8RL6qlC6x2hkCFsHYWt28ug82auZUHhW2mJwzdbJx5iHw7tHJiwXvBbXFs0WyjOB/J/mh/H+ohlcI5zH9S8pGgypMeFUen3wpgP18auiigARyhCTgtBRoWos9TmM16DMjskronEjvC3ArCBll5nUiuU0mrpPVfADSycMrYR2Glw3KhkwGAxbM3QMAq476U67JctXWPuqBnLazDPQ==';
		'backupmover/root@grosley':
			ensure  => present,
			user	=> backupmover,
			type	=> 'ssh-rsa',
			key	 => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAxFTyC11zMrjacT0aXzAbBUKDkUYpQrxQFC/lnb7vO4aQkAZx3eC3IU0Xe5dDTK97CSOeuexkHOU4++dUXcbeBmsXX0lr/za7M5mb0IKRTxvk8+arls+WhPCZctimhsIHg/vfhGT0s57LHQHAXVmGTumYdQ3rbOVfsHubgjhyT7u2nlLLUi/cG2yP5S4nKF16wiXljrdcUdjNSXN5jsW6U0M/hNgFcz2uI33s6hNWPUcOfaHCwfI0FgOBdsNTlRyCqFydKoa9kd2NKVbdO3L3q0xOdugaUsnRuEKNi3pEQKVOxWy1o62oR1gL9NUwzJJiOA9dahDZ2z9ej696aEBW4w==';
		'backupmover/root@silicon':
			ensure  => present,
			user	=> backupmover,
			type	=> 'ssh-rsa',
			key	 => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAs/tHmvah83UkyjJN/5JTm1Yo7ahh9bfi7Y7bnoryJ+F1QWnY0UNP+d8jGHoirYQoy4KvO+mpGTW2+vheD8+nmvq//2k95KkDmdo6NZul9Tn9vdpZ9VAbfmOhFmT4lhqm8IhMrA6W7+qiiBdAjMYRzdhxuzVZnjqxPWn9rznNy1g44iulFHKHAqjjwf/gMs2nYHdVBC3Re8cKwFcsz06BhvUjnZ94F80aNw8n5JsPv5ud8R8gSFaxEM6STY2mCj5liw+s5fRObgDtAE6xGALsHcOyEbI+FX1x0r/+5WOzEpM2qWLR6WJXi2HsOYfqaiqzSm2Yb3AfGi98gnnWF75e/Q==';
		'backupmover/root@loudon':
			ensure  => present,
			user	=> backupmover,
			type	=> 'ssh-rsa',
			key	 => 'AAAAB3NzaC1yc2EAAAABIwAAAgEAxrFa52jnHKDphkJBJWENCvBdopcnW74PI4dCQ39uUgSHqcbsy44peDOuTlIOoRG/uyYxRF7akR6Zd3ejgS9loVrF6dJB8VMwt7NMPqMwhmbTpZSrO+Yqu2v53Wx6ntTB+FJ1mhIJYFAzvJ3Cp3UGbd1whK1iIzi9t+x1rBg7VvChnmYogSTKuN8CzR9O4hA2hT+qFlWCcQJDBn7GaA3vwrtpCNu8kjdSs3N3ld1IazI9w0HRmso4qMRqP1vayUrPlGf1eEJZjZJ4CbLwiwhRh0orNAuERtUMOb3JWsIhTjj8F5zKW2ktUkxLZEgbBoj0nNvPwRIBPE8hXZP2SgjcArocJYTGsx0uyAT8DI5+F0aUScuxYhYf/59j4U1YQ43VvIArgMkXHG6/WXXsSeMqWOWfWPK8O1GYWUk1EfJ3elkBZFT8WnGB8OtJTaK//sIEWJpevElPKSxD74s1/TKP0Br/itkeuAFxv7z4UQI4NVU+WfCdI17NS/aasnRQeaVFCkQV+LSPVX8mLpky8j0U/B5y0oTChggZMymjjAhsa6N1CVIgHbugcM6+k4NHFBFU+l6pCbq206Q+MTq3hgSEzu6dd52XP1zMvqDmrp0G5sFK0Obo7YTx7EMhimttvsEUZ4NFWYDCfF57CYPjpaEXKmlSdbnCDE0MF71YWE1Yiik=';
	}

}


class misc::fundraising::jenkins {

	system_role { 'misc::fundraising::jenkins': description => 'fundraising jenkins server' }

	# FIXME: remove and use Jenkins from the WMF repository
	exec {
		'jenkins-apt-repo-key':
			unless => '/bin/grep "deb http://pkg.jenkins-ci.org/debian-stable binary/" /etc/apt/sources.list.d/*',
			command => '/usr/bin/wget -q -O - http://pkg.jenkins-ci.org/debian-stable/jenkins-ci.org.key | /usr/bin/apt-key add -';

		'jenkins-apt-repo-add':
			subscribe => Exec['jenkins-apt-repo-key'],
			refreshonly => true,
			command => '/bin/echo "deb http://pkg.jenkins-ci.org/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list';

		'do-an-apt-get-update':
			subscribe => Exec['jenkins-apt-repo-add'],
			refreshonly => true,
			command => '/usr/bin/apt-get update';
	}

	package { jenkins:
		ensure => latest;
	}

	user { jenkins:
		name => 'jenkins',
		groups => [ 'wikidev' ];
	}

	service { 'jenkins':
		enable => true,
		ensure => 'running',
		hasrestart => true,
		start => '/etc/init.d/jenkins start',
		stop => '/etc/init.d/jenkins stop';
	}

	monitor_service { 'jenkins': description => 'jenkins_service_running', check_command => 'nrpe_check_jenkins' }

	include misc::fundraising::jenkins_maintenance

}


class misc::fundraising::jenkins_maintenance {

	file {
		'/usr/local/bin/jenkins_watcher':
			owner => root,
			group => root,
			mode => 0500,
			source => 'puppet:///private/misc/fundraising/jenkins_watcher';
		'/usr/local/bin/jenkins_archiver':
			owner => root,
			group => root,
			mode => 0500,
			source => 'puppet:///private/misc/fundraising/jenkins_archiver';
	}

	cron {
		'jenkins_archiver':
			user => root,
			minute => '50',
			command => '/usr/local/bin/jenkins_archiver',
			ensure => present;
		'jenkins_watcher':
			user => root,
			minute => '*/5',
			command => '/usr/local/bin/jenkins_watcher',
			ensure => present;
	}

}
