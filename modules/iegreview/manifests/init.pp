# = Class: iegreview
#
# This class provisions the IEG grant review application.
#
# == Parameters:
# [+hostname+]
#   Hostname for apache vhost. Default iegreview.wikimedia.org.
#
# [+deploy_dir+]
#   Directory application is deployed to.
#   Default /srv/deployment/iegreview/iegreview.
#
# [+cache_dir+]
#   Directory for caching twig templates. Default /var/cache/iegreview.
#
# [+udp2log_dest+]
#   Log destination. Default 10.64.0.21:8420.
#
# [+serveradmin+]
#   Administrative contact email address. Default root@wikimedia.org.
#
# [+mysql_host+]
#   MySQL database server. Default localhost.
#
# [+mysql_db+]
#   MySQL database. Default iegreview.
#
# [+smtp_host+]
#   Outgoing email relay. Default localhost.
#
# [+require_ssl+]
#   Should ssl be required? Default false.
#
# == Sample usage:
#
#   class { 'iegreview':
#       require_ssl => true,
#   }
#
class iegreview(
    $hostname     = 'iegreview.wikimedia.org',
    $deploy_dir   = '/srv/deployment/iegreview/iegreview',
    $cache_dir    = '/var/cache/iegreview',
    $udp2log_dest = '10.64.0.21:8420',
    $serveradmin  = 'root@wikimedia.org',
    $mysql_host   = 'localhost',
    $mysql_db     = 'iegreview',
    $smtp_host    = 'localhost',
    $require_ssl  = false,
) {
    include ::passwords::mysql::iegreview
    include ::webserver::php5
    include ::webserver::php5-mysql
    include ::apache::mod::rewrite

    $mysql_user = $passwords::mysql::iegreview::app_user
    $mysql_pass = $passwords::mysql::iegreview::app_password
    $log_file   = "udp://${udp2log_dest}/iegreview"

    system::role { 'iegreview':
        description => 'IEG grant review server'
    }

    package { 'iegreview':
        provider => 'trebuchet',
    }

    apache::site { $hostname:
        content => template('iegreview/apache.conf.erb'),
    }

    file { "${deploy_dir}/.env":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('iegreview/env.erb'),
        require => Package['iegreview'],
        notify  => Service['apache2'],
    }

    file { $cache_dir:
        ensure => directory,
        mode   => '0755',
        owner  => 'www-data',
        group  => 'root',
    }
}
# vim:sw=4 ts=4 sts=4 et:
