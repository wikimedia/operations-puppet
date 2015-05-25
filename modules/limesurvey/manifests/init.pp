# = Class: limesurvey
#
# This class installs/configures/manages the LimeSurvey application.
#
# == Parameters:
# - $hostname: hostname for apache vhost
# - $deploy_dir: directory application is deployed to
# - $cache_dir: directory for caching twig templates
# - $udp2log_dest: log destination
# - $serveradmin: administrative contact email address
# - $mysql_host: mysql database server
# - $mysql_db: mysql database
# - $smtp_host: outgoing email relay
#
# == Sample usage:
#
#   class { 'limesurvey':
#   }
#
class limesurvey(
    $hostname     = 'limesurvey.wikimedia.org',
    $deploy_dir   = '/srv/deployment/limesurvey/limesurvey',
    $cache_dir    = '/var/cache/limesurvey',
    $udp2log_dest = '10.64.0.21:8420',
    $serveradmin  = 'noc@wikimedia.org',
    $mysql_host   = 'localhost',
    $mysql_db     = 'limesurvey',
    $smtp_host    = 'localhost'
) {

    include passwords::mysql::limesurvey,
        webserver::php5

    require_package('php5-mysql')

    $mysql_user = $passwords::mysql::limesurvey::app_user
    $mysql_pass = $passwords::mysql::limesurvey::app_password
    $log_file   = "udp://${udp2log_dest}/limesurvey"

    system::role { 'limesurvey':
        description => 'LimeSurvey server'
    }

    package { 'limesurvey':
        provider => 'trebuchet',
    }

    apache::site { 'limesurvey.wikimedia.org':
        content => template('limesurvey/apache.conf.erb'),
    }

    file { $deploy_dir:
        ensure  => directory,
    }

    file { "${deploy_dir}/.env":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Service['apache2'],
        content => template('limesurvey/env.erb'),
    }

    file { $cache_dir:
        ensure => directory,
        mode   => '0755',
        owner  => 'www-data',
        group  => 'root',
    }

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    file { '/etc/apache2/conf.d/namevirtualhost':
        source => 'puppet:///files/apache/conf.d/namevirtualhost',
        mode   => '0444',
        notify => Service['apache2'],
    }
}
# vim:sw=4 ts=4 sts=4 et:
