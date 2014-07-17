# RT - Request Tracker
#
#  This will create a server running RT with apache.
#
class misc::rt(
    $dbuser,
    $dbpass,
    $site    = 'rt.wikimedia.org',
    $dbhost  = 'localhost',
    $dbport  = '3306',
    $datadir = '/var/lib/mysql',
) {
    if ! defined(Class['webserver::php5']) {
        class {'webserver::php5': ssl => true; }
    }

    $rt_mysql_user = $dbuser
    $rt_mysql_pass = $dbpass
    $rt_mysql_host = $dbhost
    $rt_mysql_port = $dbport

    package { [ 'request-tracker4',
                'rt4-db-mysql',
                'rt4-clients',
                'libdbd-pg-perl' ]:
        ensure => latest;
    }

    $rtconf = '# This file is for the command-line client, /usr/bin/rt.\n\nserver http://localhost/rt\n'

    file {
        '/etc/request-tracker4/RT_SiteConfig.d/50-debconf':
            require => Package['request-tracker4'],
            content => template('rt/50-debconf.erb'),
            notify  => Exec['update-rt-siteconfig'];
        '/etc/request-tracker4/RT_SiteConfig.d/51-dbconfig-common':
            require => Package['request-tracker4'],
            content => template('rt/51-dbconfig-common.erb'),
            notify  => Exec['update-rt-siteconfig'];
        '/etc/request-tracker4/RT_SiteConfig.d/80-wikimedia':
            require => Package['request-tracker4'],
            source  => 'puppet:///files/rt/80-wikimedia',
            notify  => Exec['update-rt-siteconfig'];
        '/etc/request-tracker4/RT_SiteConfig.pm':
            require => Package['request-tracker4'],
            owner   => 'root',
            group   => 'www-data',
            mode    => '0440';
        '/etc/request-tracker4/rt.conf':
            require => Package['request-tracker4'],
            content => $rtconf;
    }

    # the password-reset self-service form
    file { [
        '/usr/local/share/request-tracker4/html',
        '/usr/local/share/request-tracker4/html/Callbacks',
        '/usr/local/share/request-tracker4/html/Callbacks/Default',
        '/usr/local/share/request-tracker4/html/Callbacks/Default/Elements',
        '/usr/local/share/request-tracker4/html/Callbacks/Default/Elements/Login']:
            ensure => 'directory',
            owner  => 'root',
            group  => 'staff',
            mode   => '0755',
    }

    file {
        '/usr/local/share/request-tracker4/html/Callbacks/Default/Elements/Login/AfterForm':
            ensure => present,
            owner  => 'root',
            group  => 'staff',
            mode   => '0644',
            source => 'puppet:///files/rt/AfterForm',
    }

    # RT Shredder plugin
    file {
        '/var/cache/request-tracker4/data/RT-Shredder':
            ensure => 'directory',
            owner  => 'www-data',
            group  => 'www-data',
            mode   => '0750',
    }

    exec { 'update-rt-siteconfig':
        command     => '/usr/sbin/update-rt-siteconfig-4',
        subscribe   => File[
                            '/etc/request-tracker4/RT_SiteConfig.d/50-debconf',
                            '/etc/request-tracker4/RT_SiteConfig.d/51-dbconfig-common',
                            '/etc/request-tracker4/RT_SiteConfig.d/80-wikimedia'
                       ],
        require     => Package[ 'request-tracker4', 'rt4-db-mysql', 'rt4-clients' ],
        refreshonly => true,
        notify      => Service[apache2];
    }

    apache::site { 'rt.wikimedia.org':
        content => template('rt/rt4.apache.erb'),
    }

    # use this to have a NameVirtualHost *:443
    # avoid [warn] _default_ VirtualHost overlap

    file { '/etc/apache2/ports.conf':
        ensure => present,
        mode   => '0444',
        owner  => root,
        group  => root,
        source => 'puppet:///files/apache/ports.conf.ssl';
    }

    include ::apache::mod::perl

}
