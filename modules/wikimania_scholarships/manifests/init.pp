# = Class: wikimania_scholarships
#
# This class installs/configures/manages the Wikimania Scholarships
# application.
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
#   class { 'wikimania_scholarships':
#   }
#
class wikimania_scholarships(
    $hostname     = 'scholarships.wikimedia.org',
    $deploy_dir   = '/srv/deployment/scholarships/scholarships',
    $cache_dir    = '/var/cache/scholarships',
    $udp2log_dest = 'mwlog1001.eqiad.wmnet:8420',
    $serveradmin  = 'noc@wikimedia.org',
    $mysql_host   = 'localhost',
    $mysql_db     = 'scholarships',
    $smtp_host    = 'localhost'
) {

    include ::passwords::mysql::wikimania_scholarships
    include ::apache
    include ::apache::mod::php5

    require_package('php5-mysql')

    $mysql_user = $passwords::mysql::wikimania_scholarships::app_user
    $mysql_pass = $passwords::mysql::wikimania_scholarships::app_password
    $log_file   = "udp://${udp2log_dest}/scholarships"

    system::role { 'wikimania_scholarships':
        description => 'Wikimania Scholarships server'
    }

    package { 'scholarships':
        provider => 'trebuchet',
    }

    apache::site { 'scholarships.wikimedia.org':
        content => template('wikimania_scholarships/apache.conf.erb'),
    }

    ensure_resource('file', '/srv/deployment', {'ensure' => 'directory' })

    file { [ '/srv/deployment/scholarships', $deploy_dir ]:
        ensure  => directory,
    }

    file { "${deploy_dir}/.env":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Service['apache2'],
        content => template('wikimania_scholarships/env.erb'),
    }

    file { $cache_dir:
        ensure => directory,
        mode   => '0755',
        owner  => 'www-data',
        group  => 'root',
    }

    include ::apache::mod::rewrite
    include ::apache::mod::headers

}


# vim:sw=4 ts=4 sts=4 et:
