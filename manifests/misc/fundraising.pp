# TODO: break this up in different (sub) classes for the different services
class misc::fundraising {

    include passwords::civi,
        mysql_wmf::client::default_charset_binary

    #what is currently on grosley/aluminium
    system::role { 'misc::fundraising': description => 'fundraising sites and operations' }

    require mysql_wmf::client

    package { [ 'libapache2-mod-php5', 'php5-cli', 'php-pear', 'php5-common', 'php5-curl', 'php5-dev', 'php5-gd',
        'php5-mysql', 'php5-sqlite', 'subversion', 'phpunit', 'python-scipy', 'python-matplotlib', 'python-libxml2',
        'python-sqlite', 'python-sqlitecachec', 'python-urlgrabber', 'python-argparse', 'python-dev',
        'python-setuptools', 'python-mysqldb', 'libapache2-mod-python', 'r-base', 'r-cran-rmysql', 'python-rpy2', 'python-stompy' ]:
        ensure => latest;
    }

    file {

        '/etc/logrotate.d/fundraising-civicrm':
            owner => 'root',
            group => 'root',
            mode => 0644,
            source => 'puppet:///private/misc/fundraising/logrotate.fundraising-civicrm';

        #civicrm confs
        #'/srv/org.wikimedia.civicrm/sites/default/civicrm.settings.php':
        #    owner => 'root',
        #    group => 'www-data',
        #    mode => 0440,
        #    source => 'puppet:///private/misc/fundraising/civicrm.civicrm.settings.php';
        #'/srv/org.wikimedia.civicrm/sites/default/settings.php':
        #    owner => 'root',
        #    group => 'www-data',
        #    mode => 0440,
        #    source => 'puppet:///private/misc/fundraising/civicrm.settings.php';
        #'/srv/org.wikimedia.civicrm/fundcore_gateway/paypal':
        #    owner => 'root',
        #    group => 'www-data',
        #    mode => 0440,
        #    ensure => '/srv/org.wikimedia.fundraising/IPNListener_Standalone.php';
        #'/srv/org.wikimedia.civicrm/files':
        #    owner => 'root',
        #    group => 'www-data',
        #    mode => 2770,
        #    ensure => directory;
		#'/srv/org.wikimedia.civicrm/IPNListener_Recurring.php':
        #    owner => 'root',
        #    group => 'www-data',
        #    mode => 0440,
        #    source => 'puppet:///private/misc/fundraising/misc.IPNListener_Recurring.php';

		# fundraising wiki stuff
        #'/srv/org.wikimedia.fundraising/IPNListener_Standalone.php':
        #    owner => 'root',
        #    group => 'www-data',
        #    mode => 0440,
        #    source => 'puppet:///private/misc/fundraising/misc.IPNListener_Standalone.php';
        '/etc/fundraising/legacy_paypal_config.php':
            owner => 'root',
            group => 'www-data',
            mode => 0440,
            source => 'puppet:///private/misc/fundraising/legacy_paypal_config.php';

        #apache conf stuffs
        '/etc/apache2/sites-available/000-donate':
            owner => 'root',
            group => 'root',
            mode => 0444,
            source => 'puppet:///private/misc/fundraising/apache.conf.donate';
        '/etc/apache2/sites-available/001-civicrm':
            owner => 'root',
            group => 'root',
            mode => 0444,
            source => 'puppet:///private/misc/fundraising/apache.conf.civicrm';
        '/etc/apache2/sites-available/002-civicrm-ssl':
            owner => 'root',
            group => 'root',
            mode => 0444,
            source => 'puppet:///private/misc/fundraising/apache.conf.civicrm-ssl';
        '/etc/apache2/sites-available/003-fundraising':
            owner => 'root',
            group => 'root',
            mode => 0444,
            source => 'puppet:///private/misc/fundraising/apache.conf.fundraising';
        '/etc/apache2/sites-available/004-fundraising-ssl':
            owner => 'root',
            group => 'root',
            mode => 0444,
            source => 'puppet:///private/misc/fundraising/apache.conf.fundraising-ssl';

        # part of scheme to execute drush as a consistent user
        '/usr/local/bin/drush':
            owner => 'root',
            group => 'root',
            mode => 0555,
            source => 'puppet:///files/misc/scripts/drush-wrapper';
        '/etc/sudoers.d/drupal':
            owner => 'root',
            group => 'root',
            mode => 0440,
            source => 'puppet:///files/sudo/sudoers.drupal_fundraising';

        # php config
        '/etc/php5/apache2/php.ini':
            owner => 'root',
            group => 'root',
            mode => 0444,
            source => 'puppet:///private/php/php.ini.civicrm';
        '/etc/php5/cli/php.ini':
            owner => 'root',
            group => 'root',
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
    apache_site { 'fundraising': name => '003-fundraising' }
    apache_site { 'fundraising-ssl': name => '004-fundraising-ssl' }

}

class misc::fundraising::mail {

    system::role { 'misc::fundraising::mail': description => 'fundraising mail server' }

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
            owner => 'root',
            group => 'root',
            mode => 0444,
            content => template('exim/exim4.donate.erb');
        '/etc/exim4/wikimedia.org-fundraising-private.key':
            owner => 'root',
            group => Debian-exim,
            mode => 0440,
            source => 'puppet:///private/dkim/wikimedia.org-fundraising-private.key';
        '/etc/dovecot/dovecot.conf':
            owner => 'root',
            group => 'root',
            mode => 0444,
            source => 'puppet:///files/dovecot/dovecot.donate.conf';
        '/var/mail/civimail':
            owner => 'civimail',
            group => 'civimail',
            mode => 2755,
            ensure => directory;
        '/usr/local/bin/collect_exim_stats_via_gmetric':
            owner => 'root',
            group => 'root',
            mode => 0755,
            source => 'puppet:///files/ganglia/collect_exim_stats_via_gmetric';
        '/usr/local/bin/civimail_send':
            owner => 'root',
            group => 'wikidev',
            mode => 0710,
            source => 'puppet:///private/misc/fundraising/civimail_send';
        '/etc/amazon-audit.cfg':
            owner => 'root',
            group => 'wikidev',
            mode => 0740,
            source => 'puppet:///private/misc/fundraising/amazon-audit.cfg';
    }

    cron {
        'collect_exim_stats_via_gmetric':
            user => 'root',
            command => '/usr/local/bin/collect_exim_stats_via_gmetric',
            ensure => present;
        'exim_queue_count_for_mailer_script':
            user => 'root',
            command => '/usr/sbin/exim -bpc > /tmp/exim_queue_count.dat',
            ensure => present;
    }

}


class misc::fundraising::backup::backupmover_user {

    generic::systemuser { backupmover: name => 'backupmover', home => '/var/lib/backupmover', shell => '/bin/sh' }

    ssh_authorized_key {
        'backupmover/root@boron':
            ensure  => present,
            user    => backupmover,
            type    => 'ssh-rsa',
            key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDIljE3d12L8SEO1pkiBBJplyBDCR6zRewQ+SpGWC9pe5X/gob92Yx4P0ZELFrpC+fkZlYFh0ebe0sJilBEzpLr/BFwafXZ6RvNBhU8pMSTUkb6DN9c3jG+gSyq6UIECEuF8uqOVk+1uaFg1ve9ODVfgHGiVQISS8YW/W9dFXCi9wo8gkH4L7nxptV2lkGLcjq60OoMDuS4iOzOdeQt5jguOG43XDqgyRN4tvqG54KtIjGUQP6KNpL2kGCA4WNrPnkeiNRLV9+RyLKFDjWOTT7ELk6HifuN2pn46E1DURNL6mlfw1uaoClhMruRijpZKj9wHB4awBWk0/VwPf8rpjFp';
        'backupmover/root@indium':
            ensure  => present,
            user    => backupmover,
            type    => 'ssh-rsa',
            key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDOGHFRKrjHeejEiv4tIs/MLt5+BFRquh1HlGs+iRM672xv32RtU/G3vhAWqEmGjXAFgrKB3O6faEXr4c4SJ3Vlxvr6fEsBAB0pe4GW0IJgD0HfiyIqL0m1NDU6molt79hamRmL8kBwCuRUDISbmUJw7MCNYzTd8IiE2/5Asha9QdQS1RuhkcNsaL+9jH4/wU9NND7TXpf1qu8Rd8t7HAVgxRmx0ikkTu3YeuYXdlEIoDfWeBtoStCi50uA91ckdDIsCIXLcfctMX5cRQbTtY2OgxJIWUsgiraac8rAE35gmthSVRrW3HoZGya0Fz5YlN+YLIrUkZHz1Ghx3boZgke1';
        'backupmover/root@aluminium':
            ensure  => present,
            user    => backupmover,
            type    => 'ssh-rsa',
            key     => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAv86yzKoTo6pcgfJVQ51FAIcQ8NwUhWd93SKNRTqDmIkkMOe6lVruEManMOqJXGcVWp8WpCvqzkIyx77Y5HZISzVZL3hEfkJL85HyOn8gWB9jF2uNYa16Ik2nXR/HxP0w/xajJM8RL6qlC6x2hkCFsHYWt28ug82auZUHhW2mJwzdbJx5iHw7tHJiwXvBbXFs0WyjOB/J/mh/H+ohlcI5zH9S8pGgypMeFUen3wpgP18auiigARyhCTgtBRoWos9TmM16DMjskronEjvC3ArCBll5nUiuU0mrpPVfADSycMrYR2Glw3KhkwGAxbM3QMAq476U67JctXWPuqBnLazDPQ==';
        'backupmover/root@barium':
            ensure  => present,
            user    => backupmover,
            type    => 'ssh-rsa',
            key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDSnKG77CY/0xJb2x8+iZx4o7pCBLnc90M7msL/vB5mSBlyu3asPnaBk2H9Eqe5dv+eXOx53DhRwVZ2ttdsFb2ufKdk6fjesqOcb9XDWwPN5y1WUtUxWFlULxTa9DGKOMHPIy6XQ9/6N2buSRsIlk9ZT6dz1Rue01bPXE6WSaLNRqqvrKV+nBDQtqacwZRcKLIK+a8h/x3Y8ePtnwnmi5xkYMNFwHk/EEnjfjIqTYTJlRbEaXuzGsU+QbT1brlIiQP4zMF2CiohqbCAKH7YtRZfSKCqU9+x4PQKOJQnXjMTxMEOdAQ65WLd3LtFG1VhvBxUeKYpOBxVDxmTgu5zER1p';
        'backupmover/root@backup4001':
            ensure  => present,
            user    => backupmover,
            type    => 'ssh-rsa',
            key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQCijKtdF3sRPSQzcOo16G7prTyy9r901QfqvVabazKcS9rxd7ry+42Y+VIIhSzOdZ9P68nZf1v3SlN4A7kSngY1JqolaFOXmiYpKuNE/mM9yPcu+HpQyGw0Kq8alMqGiLwiy6jbN1strz2lCMrQiRZH9v8SrCbkJ7QQTxeKycpJLlBSFTuWxzuPlw8swkG9DaewyqhIW5Hu/7CrctlQjxDSHmtVuQtsfN0wOg88jTKVsixjNZIKio3QFqQt2BQUNP3Ddr/YSz7+Ks6ImDSGCT7IEpmD9S5A4/ksyeQvRwAVf7cqvJid6ZCBz+bSOiNPk78Sf8P71AkunMwEbj4T+TWF';
    }

}


class misc::fundraising::udp2log_rotation {

    include accounts::file_mover

    sudo::user { "file_mover": privileges => ['ALL = NOPASSWD: /usr/bin/killall -HUP udp2log'] }

    file {
        '/usr/local/bin/rotate_fundraising_logs':
            owner => root,
            group => root,
            mode => 0555,
            source => 'puppet:///files/misc/scripts/rotate_fundraising_logs';
        '/a/log/fundraising/logs/buffer':
            ensure => directory,
            owner => file_mover,
            group => wikidev,
            mode => 0750;
    }

    cron {
        'rotate_fundraising_logs':
            user => file_mover,
            minute => '*/15',
            command => '/usr/local/bin/rotate_fundraising_logs',
            ensure => present;
    }

    class { "nfs::netapp::fr_archive": mountpoint => "/a/log/fundraising/logs/fr_archive" }

}
