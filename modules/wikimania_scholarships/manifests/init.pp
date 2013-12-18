# = Class: wikimania_scholarships
#
# This class installs/configures/manages the Wikimania Scholarships
# application.
#
# == Parameters:
# - $open_date: date/time that applications will first be accepted
# - $close_date: date/time after which applications will no longer be accepted
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
#       open_date => '2014-01-01T00:00:00Z',
#       close_date => '2014-02-28T23:59:59Z'
#   }
#
class wikimania_scholarships(
    $open_date    = 'UNSET',
    $close_date   = 'UNSET',
    $hostname     = 'scholarships.wikimedia.org',
    $deploy_dir   = '/srv/deployment/scholarships/scholarships',
    $cache_dir    = '/var/cache/scholarships',
    $udp2log_dest = '10.64.0.21:8420',
    $serveradmin  = 'root@wikimedia.org',
    $mysql_host   = 'localhost',
    $mysql_db     = 'scholarships',
    $smtp_host    = 'localhost'
) {

    include passwords::mysql::wikimania_scholarships,
        webserver::php5,
        webserver::php5-mysql

    $mysql_user = $passwords::mysql::wikimania_scholarships::app_user
    $mysql_pass = $passwords::mysql::wikimania_scholarships::app_password
    $log_file   = "udp://${udp2log_dest}/scholarships"

    # Check arguments
    if $open_date == 'UNSET' {
        fail('$open_date must be a date parsable by PHP\'s strtotime()')
    }
    if $close_date == 'UNSET' {
        fail('$close_date must be a date parsable by PHP\'s strtotime()')
    }

    system::role { 'wikimania_scholarships':
        description => 'Wikimania Scholarships server'
    }

    # Trebuchet deployment
    deployment::target { 'scholarships': }

    file {
        "/etc/apache2/sites-available/${hostname}":
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            notify  => Service['apache2'],
            content => template('wikimania_scholarships/apache.conf.erb');

        $deploy_dir:
            ensure  => directory;

        "${deploy_dir}/.env":
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            notify  => Service['apache2'],
            content => template('wikimania_scholarships/env.erb');

        $cache_dir:
            ensure => directory,
            mode   => '0755',
            owner  => 'www-data',
            group  => 'root';
    }

    # Webserver setup
    exec { 'enable mod_rewrite':
        command => '/usr/sbin/a2enmod rewrite',
        unless  => '/usr/sbin/apache2ctl -M | /bin/grep -q rewrite',
        notify  => Service['apache2'],
    }

    apache_site { 'wikimania_scholarships': name => $hostname }

    apache_confd { 'namevirtualhost':
        install => true,
        name    => 'namevirtualhost'
    }
}
# vim:sw=4 ts=4 sts=4 et:
