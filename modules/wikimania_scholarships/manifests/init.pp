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
    Stdlib::Fqdn $hostname       = 'scholarships.wikimedia.org',
    Stdlib::Unixpath $deploy_dir = '/srv/deployment/scholarships/scholarships',
    Stdlib::Unixpath $cache_dir  = '/var/cache/scholarships',
    Stdlib::Fqdn $udp2log_host   = 'mwlog1002.eqiad.wmnet',
    Stdlib::Port $udp2log_port   = 8420,
    String $serveradmin          = 'noc@wikimedia.org',
    Stdlib::Host $mysql_host     = 'localhost',
    String $mysql_db             = 'scholarships',
    Stdlib::Host $smtp_host      = 'localhost'
){

    include ::passwords::mysql::wikimania_scholarships

    ensure_packages(['php-mysql'])

    $mysql_user = $passwords::mysql::wikimania_scholarships::app_user
    $mysql_pass = $passwords::mysql::wikimania_scholarships::app_password
    $log_file   = "udp://${udp2log_host}:${udp2log_port}/scholarships"

    system::role { 'wikimania_scholarships':
        description => 'Wikimania Scholarships server'
    }

    scap::target { 'scholarships/scholarships':
        service_name => 'scholarships',
        deploy_user  => 'deploy-service'
    }

    httpd::site { 'scholarships.wikimedia.org':
        content => template('wikimania_scholarships/apache.conf.erb'),
    }

    file { '/etc/wikimania-scholarships.ini':
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
}

# vim:sw=4 ts=4 sts=4 et:
